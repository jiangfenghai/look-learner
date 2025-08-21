// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28; // 指定Solidity版本

import "@openzeppelin/contracts/access/Ownable.sol"; // 引入Ownable模块，实现合约拥有者控制权限
import "./interfaces/InscriptionStorageImpl.sol";    // 引入接口定义（用于函数声明）

// 主合约 InscriptionStorage，继承自 Ownable 和接口 InscriptionStorageImpl
contract InscriptionStorage is Ownable, InscriptionStorageImpl {
    
    // 构造函数，设置合约部署者为初始 owner
    constructor() Ownable(msg.sender) {}

    // 限制修饰器：只允许被授权地址访问
    modifier onlyAL() {
        require(
            isAccessable[msg.sender], // 检查是否在白名单中
            "address is not allowable to access storage" // 错误提示
        );
        _; // 执行函数主体
    }

    // 获取当前白名单地址列表（允许访问 storage 的地址）
    function getAllowableList()
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory list = new address[](accessableList.length); // 初始化数组
        for (uint8 i = 0; i < accessableList.length; i++) {
            address op = accessableList[i]; // 遍历白名单地址
            if (isAccessable[op]) {
                list[i] = op; // 如果在白名单中，加入返回数组
            }
        }
        return list; // 返回结果
    }

    // 判断某个 NFT 是否已上架（通过合约地址+TokenID定位订单）
    function isListed(address nftContract, uint256 tokenId) external view override returns(bool) {
        bytes32 orderId = keccak256(abi.encodePacked(nftContract, tokenId)); // 生成订单ID
        Order memory order = orders[orderId]; // 获取订单
        return order.exists; // 返回是否存在
    }

    // 获取总交易次数
    function getTradingCount() external view override returns(uint256) {
        return tradingCount;
    }

    // 获取所有订单数量
    function getTotal() external view override returns(uint256) {
        return orderIDs.length;
    }

    // 获取总交易量（单位由业务定义）
    function getVolume() external view override returns(uint256) {
        return volume;
    }

    // 获取指定 Token 的总交易量
    function getVolumeByToken(address tokenContract) external view override returns(uint256) {
        return volumeByToken[tokenContract];
    }

    // 获取某个地址（用户）的所有订单
    function getMyOrders(address owner) external view override returns (Order[] memory) {
        return myOrders[owner];
    }

    // 分页获取订单（page从1开始，pageSize为每页条数）
    function getOrders(uint256 page, uint256 pageSize) external view override returns (Order[] memory) {
        Order[] memory all = new Order[](pageSize); // 初始化返回数组
        uint256 index = (page - 1) * pageSize;       // 计算起始索引
        uint256 offset = index + pageSize;           // 结束索引
        uint256 length = orderIDs.length;            // 总长度
        uint256 bound = offset > length ? length : offset; // 防止越界
        for (uint256 i = index; i < bound; i++) {
            all[i - index] = orders[orderIDs[i]]; // 获取订单填入数组
        }
        return all;
    }

    // 获取某个地址的全部交易记录
    function getTradeRecordsByAddress(address wallet) external view override returns (TradeRecord[] memory) {
        return tradingRecords[wallet];
    }

    // 设置是否允许某个地址访问（添加/移除白名单）
    function setAccessableAddr(
        address operator,
        bool status
    ) external override onlyOwner {
        isAccessable[operator] = status;
    }

    // 设置某个订单的单价
    function setListPrice(
        bytes32 orderId,
        uint256 unitPrice
    ) external override onlyAL {
        Order storage order = orders[orderId];
        order.unitPrice = unitPrice;
    }

    // 设置某个订单的存在状态（上架/下架）
    function setOrderStatus(bytes32 orderId, bool status) external override onlyAL {
        orders[orderId].exists = status;
    }

    // 创建订单并存储（只允许白名单地址操作）
    function createOrder(
        bytes32 orderId,
        Order calldata order
    ) external override onlyAL {
        orders[orderId] = order; // 存储订单
        orderIDIndex[orderId] = orderIDs.length; // 记录索引
        orderIDs.push(orderId); // 添加到列表
        myOrders[tx.origin].push(order); // 添加到用户订单
    }

    // 删除订单并更新索引
    function deleteOrder(bytes32 orderId) external override onlyAL {
        Order memory order = orders[orderId]; // 获取订单
        address orderOwner = order.seller;    // 获取卖家地址
        Order[] storage myorders = myOrders[orderOwner]; // 获取该用户的订单列表

        // 遍历查找该订单
        for (uint256 i = 0; i < myorders.length; i++) {
            Order memory _myorder = myorders[i];
            if (_myorder.orderId == orderId) {
                delete myorders[i]; // 删除该项
                myorders[i] = myorders[myorders.length - 1]; // 将最后一项移到当前位置
                myorders.pop(); // 删除最后一项
            }
        }

        delete orders[orderId]; // 删除主 orders 映射中的订单记录

        // 删除 orderIDs 中的 ID，并更新 index 映射
        uint256 index = orderIDIndex[orderId];
        orderIDs[index] = orderIDs[orderIDs.length - 1];
        orderIDIndex[orderIDs[index]] = index;
        orderIDs.pop();
    }

    // 创建交易记录
    function createTradeRecord(bytes32 orderId, address from, address to, string calldata tradeEvent) external override onlyAL {
        tradingRecords[from].push(TradeRecord(
            orders[orderId], // 当前订单信息
            from,            // 卖方地址
            to,              // 买方地址
            tradeEvent,      // 交易事件名称
            block.timestamp  // 时间戳
        ));
    }

    // 累加总交易量，并对特定 Token 做分类累加
    function accumulateVolume(uint256 value, address tokenContract) external override onlyAL {
        volume += value;
        volumeByToken[tokenContract] += value; 
    }

    // 累加交易笔数
    function accumulateTradingCount() external override onlyAL {
        tradingCount += 1;
    }
}
