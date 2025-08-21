// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14; // solidity 版本声明（需补全，建议写 ^0.8.20 这样更规范）

// 导入 ScriptionToNFT 合约
import "./ScriptionToNFT.sol";
// 导入 OpenZeppelin 提供的 Ownable 合约（用于所有权管理）
import "@openzeppelin/contracts/access/Ownable.sol";

// 定义 Scription2NFT 的接口，便于工厂合约通过接口操作具体的 NFT 合约
interface IScription2NFT {
    // scription 结构体，描述脚本对应的 NFT 元信息
    struct _scription {
        uint256 tokenId;
        uint256 chainID;
        string tick;
        string protocol;
        uint256 amount;
        address owner;
        address contractAddr;
    }

    // 铸造 NFT 的接口函数
    function mintScriptionToNFT(
        _scription memory scriptionData,
        uint256 _nonce,
        uint256 _blockHeight,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external;

    // 销毁 NFT 的接口函数
    function burnScriptionNFT(uint256 _tokenId, address _owner) external;

    // 查询某用户所有 NFT 的接口函数
    function getUserMintTokens(address _owner)
        external
        view
        returns (_scription[] memory _userTokens);
}

// 工厂合约定义，继承 Ownable 实现所有权管理
contract scriptionToNFT_Factory is Ownable  {
    // 多级 mapping：chainId => protocol => tick => NFT 合约地址
    
    mapping(uint256 => mapping(string => mapping(string => address)))
        public collection;

    // 保存所有部署过的 ScriptionToNFT 合约实例
    ScriptionToNFT[] public collections;

    // 合约激活状态 mapping，记录每个合约是否可用
    mapping(address => bool) public activated;

    // 存储集合合约的详细信息
    struct collectionInfo {
        uint256 chainId;
        string protocol;
        string tick;
    }

    // 合约地址到 collectionInfo 的映射
    mapping(address => collectionInfo) public addrToCollections;

    // 控制器地址（只有 controller 才能调用关键函数）
    mapping(address => bool) public controller;

    // 仅允许 controller 角色调用的修饰器
    modifier onlyController() {
        require(controller[msg.sender], "permission denied");
        _;
    }

    // 存储所有签名者地址
    address[] public signers;
    // scription 的总数量上限
    uint256 public scriptionLimit;
    // 单用户可 mint 的 scription 上限
    uint256 public scriptionMintLimit;
    // 有效的区块高度范围
    uint256 public blockNumberValidRange;
    // 签名者是否授权 mapping
    mapping(address => bool) public signerAuthorized;

    // 新集合合约创建事件
    event newCollectionEvent(collectionInfo _info, address _collectionAddr);

    // 集合激活/停用状态变更事件
    event collectionStatusChangeEvent(
        collectionInfo _info,
        address _collectionAddr,
        bool _activated
    );

    // 构造函数，初始化签名者、限制参数
    constructor(
        address[] memory _signers,
        uint256 _scriptionLimit,
        uint256 _scriptionMintLimit,
        uint256 _blockNumberValidRange
    ) Ownable (msg.sender){
        // 遍历签名者，去重并初始化
        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(!signerAuthorized[signer], "Duplicate existence");
            signers.push(signer);
            signerAuthorized[signer] = true;
        }
        scriptionLimit = _scriptionLimit; // 总额度
        scriptionMintLimit = _scriptionMintLimit; // 单用户额度
        blockNumberValidRange = _blockNumberValidRange; // 区块有效范围
    }

    // 内部函数，判断合约是否处于激活状态
    function onlyActivated(address _collection) internal view {
        require(activated[_collection], "Suspension of use collection");
    }

    // 添加 controller 角色，只允许合约拥有者调用
    function addController(address _controller) external onlyOwner{
      require(!controller[_controller],"controller already exists");
      controller[_controller] = true;
    }

    // 移除 controller 角色，只允许合约拥有者调用
    function removeController(address _controller) external onlyOwner{
      require(controller[_controller], "none exist controller");
      delete controller[_controller];
    }

    // 包裹函数，实现 NFT 合约的自动部署和脚本转 NFT
    function wrap(
        IScription2NFT._scription memory scriptionData,
        uint256 _nonce,
        uint256 _blockHeight,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external onlyController {
        // 查询已存在的集合合约
        address _collection = collection[scriptionData.chainID][
            scriptionData.protocol
        ][scriptionData.tick];
        // 如果集合合约不存在，则自动部署
        if (_collection == address(0)) {
            ScriptionToNFT newCollection = new ScriptionToNFT(
                scriptionData.tick,   // 名称
                scriptionData.tick,   // 符号
                owner(),              // 合约拥有者
                signers,              // 签名者
                address(this),        // 工厂地址
                scriptionLimit,       // 总额度
                scriptionMintLimit,   // 用户额度
                blockNumberValidRange // 区块高度范围
            );
            _collection = address(newCollection);
            // 注册到 mapping
            collection[scriptionData.chainID][scriptionData.protocol][
                scriptionData.tick
            ] = _collection;
            // 存储集合信息
            addrToCollections[_collection] = collectionInfo({
                chainId: scriptionData.chainID,
                protocol: scriptionData.protocol,
                tick: scriptionData.tick
            });
            // 收集合约到数组
            collections.push(newCollection);
            // 激活新合约
            activated[_collection] = true;
            // 事件通知
            emit newCollectionEvent(
                collectionInfo({
                    chainId: scriptionData.chainID,
                    protocol: scriptionData.protocol,
                    tick: scriptionData.tick
                }),
                _collection
            );
        }
        // 确保合约已激活
        onlyActivated(_collection);
        // 调用集合合约的 mintScriptionToNFT 方法进行实际 mint
        IScription2NFT(_collection).mintScriptionToNFT(
            scriptionData,
            _nonce,
            _blockHeight,
            v,
            r,
            s
        );
    }

    // 解包函数，调用集合合约的 burnScriptionNFT
    function unwrap(
        collectionInfo memory _info,
        uint256 _tokenId,
        address _owner
    ) external onlyController {
        // 查找集合合约
        address _collection = collection[_info.chainId][_info.protocol][
            _info.tick
        ];
        // 如果未找到，报错
        if (_collection == address(0)) {
            revert("Invalid scription info");
        }

        // 确认激活
        onlyActivated(_collection);

        // 调用集合合约销毁 NFT
        IScription2NFT(_collection).burnScriptionNFT(_tokenId, _owner);
    }

    // 查询某用户在指定集合下的所有 NFT
    function getUserMintTokens(collectionInfo memory _info, address _owner)
        public
        view
        returns (IScription2NFT._scription[] memory _userTokens)
    {
        address _collection = collection[_info.chainId][_info.protocol][
            _info.tick
        ];
        if (_collection == address(0)) {
            revert("Invalid scription info");
        }

        return IScription2NFT(_collection).getUserMintTokens(_owner);
    }

    // 停用指定集合合约，只能由 owner 操作
    function deactivateCollection(collectionInfo memory _info)
        external
        onlyOwner
    {
        address _collection = collection[_info.chainId][_info.protocol][
            _info.tick
        ];

        if (_collection != address(0)) {
            if (activated[_collection]) {
                activated[_collection] = false;
                emit collectionStatusChangeEvent(_info, _collection, false);
            } else {
                revert("this collection already deactivated");
            }
        } else {
            revert("collection doesn't exist");
        }
    }

    // 重新激活集合合约，只能由 owner 操作
    function reactivatedCollection(collectionInfo memory _info)
        external
        onlyOwner
    {
        address _collection = collection[_info.chainId][_info.protocol][
            _info.tick
        ];
        if (_collection != address(0)) {
            if (!activated[_collection]) {
                activated[_collection] = true;
                emit collectionStatusChangeEvent(_info, _collection, true);
            } else {
                revert("this collection already activated");
            }
        } else {
            revert("collection doesn't exist");
        }
    }
}
