//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IInscriptionCommon.sol";
import "./INFTWrapFactory.sol";

interface IInscriptionMarket is IInscriptionCommon {
    function setStorageContract(address newStorageContract) external;

    function setNFTFactoryContract(address newNFTFactoryContract) external;

    function switchMarketStatus(bool status) external;

    function setFee(uint256 _fee) external;

    function isListed(
        address nftContract,
        uint256 tokenId
    ) external returns (bool);

    function genOrderId(
        address nftContract,
        uint256 tokenId
    ) external returns (bytes32);

    // function wrap(
    //     INFTWrapFactory.EthscriptionToNFT calldata inscription,
    //     uint256 nonce,
    //     uint256 blockHeight,
    //     uint8[] calldata v,
    //     bytes32[] calldata r,
    //     bytes32[] calldata s
    // ) external;

    // function unwrap(uint256 tokenId, address owner) external;

    function getUserWrappedInscriptions(
        address owner
    ) external returns (INFTWrapFactory.EthscriptionToNFT[] memory);

    function getOrdersTotal() external view returns (uint256);

    function getMyOrders(address owner) external view returns (Order[] memory);

    function getOrders(
        uint256 page,
        uint256 pageSize
    ) external view returns (Order[] memory);

    function getVolume() external view returns (uint256);

    function getTradeRecordsByAddress(
        address wallet
    ) external view returns (TradeRecord[] memory);

    function createOrder(Order calldata payload) external;

    function updateOrder(bytes32 orderId, uint256 unitPrice) external;

    function cancelOrder(bytes32 orderId) external;

    function acceptOrder(bytes32 orderId,uint256 buyAmount ) external payable;

    function withdraw() external;

    function withdrawToken(address tokenContract) external;
}
