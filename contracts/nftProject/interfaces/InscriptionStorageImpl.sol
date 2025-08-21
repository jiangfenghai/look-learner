//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IInscriptionCommon.sol";

abstract contract InscriptionStorageImpl is IInscriptionCommon {
    address[] public accessableList;
    bytes32[] public orderIDs;
    uint256 public volume;
    uint256 public tradingCount;
    mapping(address => uint256) public volumeByToken; 
    mapping(address => bool) public isAccessable;
    mapping(bytes32 => uint256) public orderIDIndex;
    mapping(bytes32 => Order) public orders;
    mapping(address => Order[]) public myOrders;
    mapping(address => TradeRecord[]) public tradingRecords;

    function isListed(address nftContract, uint256 tokenId) external view virtual returns (bool);
    
    function getTradingCount() external view virtual returns (uint256);

    function getTotal() external view virtual returns (uint256);

    function getVolume() external view virtual returns (uint256);

    function getVolumeByToken(address tokenContract) external view virtual returns (uint256);

    function getMyOrders(address owner) external view virtual returns (Order[] memory);

    function getOrders(
        uint256 page,
        uint256 pageSize
    ) external view virtual returns (Order[] memory);

    function getTradeRecordsByAddress(
        address wallet
    ) external view virtual returns (TradeRecord[] memory);

    function getAllowableList()
        external
        view
        virtual
        returns (address[] memory);

    function setOrderStatus(bytes32 orderId, bool status) external virtual;

    function setAccessableAddr(address operator, bool status) external virtual;

    // function setTopPrice(bytes32 askID, uint256 price) external virtual;
    function setListPrice(bytes32 orderId, uint256 price) external virtual;

    function createOrder(
        bytes32 orderId,
        Order calldata payload
    ) external virtual;

    // function createBid(bytes32 askID, address buyer, uint256 price, uint256 deadline) external virtual;
    function deleteOrder(bytes32 orderId) external virtual;

    function createTradeRecord(
        bytes32 orderId,
        address from,
        address to,
        string calldata tradeEvent
    ) external virtual;

    function accumulateVolume(uint256 value, address tokenContract) external virtual;

    function accumulateTradingCount() external virtual;
}
