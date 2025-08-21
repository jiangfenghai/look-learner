// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title IInscriptionCommon 接口
 * @dev 定义了与“铭文 NFT 挂单交易市场”相关的数据结构和事件。
 *
 * - 包含铭文结构 Inscription（p、op、tick、数量等）
 * - 包含订单结构 Order（关联 NFT、价格、卖家等）
 * - 定义交易记录 TradeRecord
 * - 定义了订单生命周期内所有关键事件（上架、下架、更新、成交）
 * - 可供挂单合约、交易合约等调用复用
 */
interface IInscriptionCommon {

    /** 铭文结构 */
    struct Inscription {
        string p;          // 协议标识，如 "brc-20"
        string op;         // 操作类型，如 "mint"、"transfer"
        string tick;       // 标记符，例如代币名（类似 ticker）
        uint256 amt;       // 本次挂单的铭文数量
        uint256 limit;     // 每张 NFT 限制的数量
    }

    /** 订单结构 */
    struct Order {
        bool exists;                    // 订单是否存在
        bytes32 orderId;               // 唯一订单 ID（通过 keccak256 生成）
        address wrappedNFTContract;    // 包装后的 NFT 合约地址
        uint256 tokenId;               // 对应的 tokenId
        string tokenSymbol;            // 对应的代币符号（如 USDT）
        address tokenContract;         // 支付代币合约地址（支持 ERC20）
        Inscription inscription;       // 铭文信息结构体
         uint256 remainingAmt;        // 新增：可售剩余量
        address seller;                // 卖家地址
        uint256 unitPrice;             // 单价（每份价格）
        uint256 createTime;            // 创建时间戳
    }

    /** 交易记录 */
    struct TradeRecord {
        Order order;        // 订单快照
        address from;       // 出售方
        address to;         // 购买方
        string op;          // 操作类型（如 "list"、"sold"）
        uint256 time;       // 交易时间
    }

    /** 挂单事件：当一个订单被上架 */
    event OrderListed(
        bytes32 orderId,
        address indexed wrappedNFTContract,
        uint256 indexed tokenId,
        string p,
        string op,
        string tick,
        uint256 amt,
        uint256 limit,
        address seller,
        uint256 unitPrice,
        string symbol,
        uint256 createTime
    );

    /** 取消挂单事件 */
    event OrderUnlisted(
        bytes32 orderId, 
        string p,
        string op,
        string tick,
        uint256 amt,
        uint256 limit,
        address seller,
        uint256 unitPrice,
        string symbol,
        uint256 unlistTime
    );

    /** 更新订单价格等信息事件 */
    event OrderUpdated(
        bytes32 orderId,
        uint256 newUnitPrice,
        string p,
        string op,
        string tick,
        uint256 amt,
        uint256 limit,
        address seller,
        string symbol,
        uint256 updateTime
    );

    /** 成交事件 */
    event OrderSold(
        bytes32 orderId,
        address buyer,
        address seller,
        string p,
        string op,
        string tick,
        uint256 amt,
        uint256 limit,
        uint256 unitPrice,
        string symbol,
        uint256 soldTime
    );

    /** 接收 ETH 时的事件（fallback/receive） */
    event Received(address Sender, uint Value);

    /** 铭文包装为 NFT 的事件 */
    event Wrap(string p, string tick, uint256 amount, address owner, uint256 chainId);

    /** NFT 解包为铭文的事件 */
    event UnWrap(string p, string op, string tick, uint256 amount, address owner);
}
