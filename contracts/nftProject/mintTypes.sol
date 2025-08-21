// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library MintTypes {
    bytes32 public constant SCRIPTION_TO_NFT =
        keccak256(
            abi.encodePacked(
                "ScriptionToNFT(address signer,address owner,bytes32[] etherscriptionTxHash,uint256 nonce,uint256 blockHeight)"
            )
        );

    struct EthscriptionToNFT {
        address signer; // signer of the ethscription seller
        address creator; // deployer of the ethscription collection
        bytes32[] etherscriptionTxHash;
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 blockHeight; // the blockHeight when the signature generate
        bytes signature;
        // uint8 v; // v: parameter (27 or 28)
        // bytes32 r; // r: parameter
        // bytes32 s; // s: parameter
    }

    function hash(
        EthscriptionToNFT memory params,
        bytes32 _domainSeparator
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparator,
                    keccak256(
                        abi.encode(
                            SCRIPTION_TO_NFT,
                            params.signer,
                            params.creator,
                            keccak256(abi.encodePacked(params.etherscriptionTxHash)),
                            params.nonce,
                            params.blockHeight
                        )
                    )
                )
            );
    }
}
