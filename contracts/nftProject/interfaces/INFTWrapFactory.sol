//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFTWrapFactory {
    struct EthscriptionToNFT {
        uint256 tokenId;
        uint256 chainId;
        string tick;
        string protocol;
        uint256 amount;
        address owner;
        address contractAddr;
    }

    function wrapScriptionToNFT(
        EthscriptionToNFT calldata payload,
        uint256 nonce,
        uint256 blockHeight,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external;

    function unWrapScription(uint256 tokenId, address owner) external;

    function getUserMintTokens(address owner) external view returns (EthscriptionToNFT[] memory);

    function getWrappedScriptionByTokenId(uint256 tokenId) external view returns (EthscriptionToNFT memory);
}
