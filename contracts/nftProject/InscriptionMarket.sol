// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// 引入 OpenZeppelin 的安全模块和标准接口
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // 防重入
import "@openzeppelin/contracts/access/Ownable.sol"; // 权限控制
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // ERC20 接口
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // ERC721 接口

// 引入自定义合约接口
import "./interfaces/INFTWrapFactory.sol";
import "./interfaces/IInscriptionMarket.sol";
import "./interfaces/InscriptionStorageImpl.sol";
import "./Constants.sol";

// 开发调试工具（Hardhat）
import "hardhat/console.sol";

// 主合约：铭文市场
contract InscriptionMarket is IInscriptionMarket, Ownable, ReentrancyGuard {
    bool isOpen = true; // 市场是否开放
    address public storageContract; // 存储合约地址
    address public nftFactoryContract; // NFT 工厂地址
    address public recipientAddress; // 接收费用或提币的地址
    uint256 public fee; // 手续费（单位：百分比）

    // 提币白名单
    mapping(address => bool) public withdrawWL;

    //新增结构体
    struct CheckNFT {
        address seller; // 卖家的地址
        address tokenContract; // 托管的代币合约地址
        uint256 totalAmount; // 托管的代币总数量
        uint256 remainingAmount; // 剩余可供购买的代币数量
        uint256 pricePerUnit; // 每单位代币的价格
        bool exists; // 标记此支票是否存在
    }
    // 支票 ID 计数器
    uint256 public checkCounter;
    mapping(uint256 => CheckNFT) public checkNFTs;
    mapping(uint256 => bool) public isNFTListed;

    // 构造函数，初始化市场配置
    constructor(
        address _storageContract,
        address _nftFactoryContract,
        uint256 _fee,
        address _recipientAddress
    ) payable Ownable(msg.sender) {
        storageContract = _storageContract;
        nftFactoryContract = _nftFactoryContract;
        fee = _fee;
        recipientAddress = _recipientAddress;
    }

    // 接收原生 ETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // 市场状态校验器
    modifier marketGuard() {
        require(isOpen, "Market is being repaired.");
        _;
    }

    // 管理员：切换市场状态（开/关）
    function switchMarketStatus(bool status) external onlyOwner {
        isOpen = status;
    }

    // 设置存储合约地址
    function setStorageContract(address newStorageContract) external onlyOwner {
        storageContract = newStorageContract;
    }

    // 设置 NFT 工厂合约地址
    function setNFTFactoryContract(address newNFTFactoryContract)
        external
        onlyOwner
    {
        nftFactoryContract = newNFTFactoryContract;
    }

    // 设置交易手续费
    function setFee(uint256 _fee) public override onlyOwner {
        require(_fee < 100, "%%");
        fee = _fee;
    }

    // 设置提币白名单权限
    function setWithdrawWL(address operator, bool status) external onlyOwner {
        withdrawWL[operator] = status;
    }

    // 设置接收地址
    function setRecipientAddress(address newRecipient) external onlyOwner {
        recipientAddress = newRecipient;
    }

    // 判断某个 NFT 是否已挂单
    function isListed(address nftContract, uint256 tokenId)
        external
        view
        returns (bool)
    {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        return _storageImpl.isListed(nftContract, tokenId);
    }

    // 获取订单总数
    function getOrdersTotal() external view returns (uint256) {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        return _storageImpl.getTotal();
    }

    // 获取市场总成交额
    function getVolume() external view returns (uint256) {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        return _storageImpl.getVolume();
    }

    // 获取某种代币的成交额
    function getVolumeByToken(address tokenContract)
        external
        view
        returns (uint256)
    {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        return _storageImpl.getVolumeByToken(tokenContract);
    }

    // 获取成交次数
    function getTradingCount() external view returns (uint256) {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        return _storageImpl.getTradingCount();
    }

    // 获取用户持有的铭文 NFT
    function getUserWrappedInscriptions(address owner)
        external
        view
        override
        returns (INFTWrapFactory.EthscriptionToNFT[] memory)
    {
        INFTWrapFactory factory = INFTWrapFactory(nftFactoryContract);
        return factory.getUserMintTokens(owner);
    }

    // 生成订单 ID（nft 地址 + tokenId 哈希）
    function genOrderId(address nftContract, uint256 tokenId)
        public
        pure
        override
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(nftContract, tokenId));
    }

    // 获取用户所有挂单
    function getMyOrders(address owner)
        external
        view
        override
        returns (Order[] memory)
    {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        return _storageImpl.getMyOrders(owner);
    }

    // 分页获取市场挂单
    function getOrders(uint256 page, uint256 pageSize)
        external
        view
        override
        returns (Order[] memory)
    {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        return _storageImpl.getOrders(page, pageSize);
    }

    // 创建新挂单（卖出）
    function createOrder(Order calldata order) external override marketGuard {
        console.log("1234");
        bytes32 orderId = genOrderId(order.wrappedNFTContract, order.tokenId);

        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        console.log(address(_storageImpl), "haha");

        // 校验订单是否已存在
        (bool exists, , , , , , , , , ,) = _storageImpl.orders(orderId);
        require(!exists, Constants.REVERT_DUPLICATED_ASK);

        // 校验 NFT 所有权和授权
        IERC721 erc721nft = IERC721(order.wrappedNFTContract);
        require(
            erc721nft.ownerOf(order.tokenId) == msg.sender,
            Constants.REVERT_NOT_OWNER
        );
        require(
            erc721nft.getApproved(order.tokenId) == address(this) ||
                erc721nft.isApprovedForAll(msg.sender, address(this)),
            Constants.REVERT_NOT_APPROVED
        );

        // 存储订单数据
        _storageImpl.createOrder(orderId, order);
        _storageImpl.createTradeRecord(
            orderId,
            msg.sender,
            address(0),
            Constants.TRADE_EVENT_LIST
        );

        // 触发挂单事件
        emit OrderListed(
            orderId,
            order.wrappedNFTContract,
            order.tokenId,
            order.inscription.p,
            order.inscription.op,
            order.inscription.tick,
            order.inscription.amt,
            order.inscription.limit,
            msg.sender,
            order.unitPrice,
            order.tokenSymbol,
            order.createTime
        );
    }

    // 修改订单价格
    function updateOrder(bytes32 orderId, uint256 unitPrice)
        external
        override
        marketGuard
    {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        (
            bool exists,
            ,
            ,
            ,
            string memory tokenSymbol,
            ,
            Inscription memory inscription,
            ,
            address seller,
            ,

        ) = _storageImpl.orders(orderId);

        require(exists, Constants.REVERT_ASK_DOES_NOT_EXIST);
        require(msg.sender == seller, Constants.REVERT_ASK_SELLER_NOT_OWNER);

        _storageImpl.setListPrice(orderId, unitPrice);
        _storageImpl.createTradeRecord(
            orderId,
            msg.sender,
            msg.sender,
            Constants.TRADE_EVENT_UPDATE
        );

        emit OrderUpdated(
            orderId,
            unitPrice,
            inscription.p,
            inscription.op,
            inscription.tick,
            inscription.amt,
            inscription.limit,
            msg.sender,
            tokenSymbol,
            block.timestamp
        );
    }

    // 取消挂单
    function cancelOrder(bytes32 orderId) external override marketGuard {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        (
            bool exists,
            ,
            ,
            ,
            string memory tokenSymbol,
            ,
            Inscription memory inscription,
            ,
            address seller,
            uint256 unitPrice,

        ) = _storageImpl.orders(orderId);
        require(exists, Constants.REVERT_ASK_DOES_NOT_EXIST);
        require(seller == msg.sender, Constants.REVERT_ASK_SELLER_NOT_OWNER);

        _storageImpl.createTradeRecord(
            orderId,
            msg.sender,
            msg.sender,
            Constants.TRADE_EVENT_UNLIST
        );
        _storageImpl.deleteOrder(orderId);

        emit OrderUnlisted(
            orderId,
            inscription.p,
            inscription.op,
            inscription.tick,
            inscription.amt,
            inscription.limit,
            msg.sender,
            unitPrice,
            tokenSymbol,
            block.timestamp
        );
    }

    // 接受订单（买入）
    function acceptOrder(bytes32 orderId ,uint256 buyAmount  ) 
        external
        payable
        override
        marketGuard
    {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        (
            bool exists,
            ,
            address wrappedNFTContract,
            uint256 tokenId,
            string memory tokenSymbol,
            address tokenContract,
            Inscription memory inscription,
            uint256 remainingAmt,
            address seller,
            uint256 unitPrice,

        ) = _storageImpl.orders(orderId);
        require(  buyAmount  > 0 &&  remainingAmt  >= buyAmount ,"invalid buy amount");
        require(exists, Constants.REVERT_ASK_DOES_NOT_EXIST);
        require(seller != msg.sender, Constants.REVERT_CANT_ACCEPT_OWN_ASK);

        IERC721 erc721nft = IERC721(wrappedNFTContract);
        require(
            erc721nft.ownerOf(tokenId) == seller,
            Constants.REVERT_ASK_SELLER_NOT_OWNER
        );

        // 转移 NFT
        erc721nft.safeTransferFrom(seller, msg.sender, tokenId, new bytes(0));
     
        // 处理支付
        uint256 totalPrice = unitPrice * inscription.amt;
        if (tokenContract == address(0)) {
            require(
                msg.value >= totalPrice,
                Constants.REVERT_INSUFFICIENT_VALUE
            );
            payable(seller).transfer(_takeFee(totalPrice));
        } else {
            IERC20 token = IERC20(tokenContract);
            uint256 income = _takeFee(totalPrice);
            uint256 cut = totalPrice - income;
            require(
                token.transferFrom(msg.sender, seller, income),
                "transfer erc20 to seller failed"
            );
            require(
                token.transferFrom(msg.sender, address(this), cut),
                "transfer erc20 to contract failed"
            );
        }

        _storageImpl.createTradeRecord(
            orderId,
            msg.sender,
            seller,
            Constants.TRADE_EVENT_BUY
        );
        _storageImpl.createTradeRecord(
            orderId,
            seller,
            msg.sender,
            Constants.TRADE_EVENT_SOLD
        );
        _storageImpl.deleteOrder(orderId);
        _storageImpl.accumulateVolume(totalPrice, tokenContract);
        _storageImpl.accumulateTradingCount();

        emit OrderSold(
            orderId,
            msg.sender,
            seller,
            inscription.p,
            inscription.op,
            inscription.tick,
            inscription.amt,
            inscription.limit,
            unitPrice,
            tokenSymbol,
            block.timestamp
        );
    }

    // 查看某地址的交易记录
    function getTradeRecordsByAddress(address wallet)
        external
        view
        override
        returns (TradeRecord[] memory)
    {
        InscriptionStorageImpl _storageImpl = InscriptionStorageImpl(
            storageContract
        );
        return _storageImpl.getTradeRecordsByAddress(wallet);
    }

    // 管理员提取 ETH
    function withdraw() external override onlyOwner {
        payable(address(msg.sender)).transfer(address(this).balance);
    }

    // 管理员提取合约中的 ERC20
    function withdrawToken(address tokenContract) external override onlyOwner {
        IERC20 token = IERC20(tokenContract);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // 白名单地址提取 ETH 到指定地址
    function withdrawForWL() external {
        require(withdrawWL[msg.sender], "Not Allowed");
        payable(recipientAddress).transfer(address(this).balance);
    }

    // 白名单地址提取指定 ERC20
    function withdrawTokenForWL(address tokenContract) external {
        require(withdrawWL[msg.sender], "Not Allowed");
        IERC20 token = IERC20(tokenContract);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(recipientAddress, balance);
    }

    // 内部函数：收取手续费（返回收入）
    function _takeFee(uint256 totalPrice) internal view returns (uint256) {
        uint256 cut = (totalPrice * fee) / 100;
        return totalPrice - cut;
    }

    //新增挂单逻辑
    function createCheck(
        address _tokenContract,
        uint256 _totalAmount,
        uint256 _pricePerUnit,
        uint256 tokenId
    ) external nonReentrant {
        // 确保挂单数量和价格有效
        require(_totalAmount > 0, "Invalid total amount");
        require(_pricePerUnit > 0, "Invalid price per unit");
        require(!isNFTListed[tokenId], "This NFT is already listed");

        // 校验 NFT 所有权和授权
        IERC721 erc721nft = IERC721(nftFactoryContract);
        require(
            erc721nft.ownerOf(tokenId) == msg.sender,
            "you are not approve"
        );
        require(
            erc721nft.getApproved(tokenId) == address(this) ||
                erc721nft.isApprovedForAll(msg.sender, address(this)),
            "you are not approve"
        );
        // 记录新的支票凭
        checkCounter++;
        checkNFTs[checkCounter] = CheckNFT({
            seller: msg.sender,
            tokenContract: _tokenContract,
            totalAmount: _totalAmount,
            remainingAmount: _totalAmount,
            pricePerUnit: _pricePerUnit,
            exists: true
        });
        isNFTListed[tokenId] = true;
    }

    //新增购买逻辑
    function buyFraction(uint256 _checkId, uint256 _partCount)
        external
        payable
        nonReentrant
    {
        CheckNFT storage check = checkNFTs[_checkId];
        // 校验：支票是否存在
        require(check.exists, "Check does not exist");
        // 校验：不能购买自己的支票
        require(check.seller != msg.sender, "Cannot buy from self");
        // 校验：剩余数量是否足够
        require(check.remainingAmount >= _partCount, "Not enough tokens left");
        require(_partCount > 0, "Part count must be > 0");
        // 处理支付
        uint256 totalPrice = check.pricePerUnit * _partCount;
        address tokenContract = check.tokenContract;
        if (tokenContract == address(0)) {
            //require(msg.value >= totalPrice, "you are not engory eth");
            require(msg.value >= totalPrice, "Need to send more ETH to buy");
            payable(check.seller).transfer(_takeFee(totalPrice));
        } else {
            IERC20 token = IERC20(tokenContract);
            uint256 income = _takeFee(totalPrice);
            uint256 cut = totalPrice - income;
            require(
                token.transferFrom(msg.sender, check.seller, income),
                "transfer erc20 to seller failed"
            );
            require(
                token.transferFrom(msg.sender, address(this), cut),
                "transfer erc20 to contract failed"
            );
        }
        // 更新支票状态
        check.remainingAmount -= _partCount;
        // 如果代币已全部售罄，删除支票
        if (check.remainingAmount == 0) {
            delete checkNFTs[_checkId];
        }
    }
}
