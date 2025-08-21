// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter = 1;
    struct EthNFT {
        uint256 tokenId;
        uint256 chainId;
        string tick;
        string protocol;
        uint256 amount;
        address owner;
        address contractAddr;
    }
    string public tick;
    string public protocol;
    EthNFT[] public ethNFTs;
    mapping(address => uint256[]) public _scriptions;

    constructor(string memory _tick, string memory _protocol)
        ERC721("MyNFT", "MNFT")
        Ownable(msg.sender)
    {
        tick = _tick;
        protocol = _protocol;
    }

    // 铸造 NFT 的函数，只有合约所有者可以调用
    function safeMint(address to, string memory uri) public onlyOwner {
        // 先递增，再赋值
        _tokenIdCounter++;
        _safeMint(to, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, uri);
        ethNFTs.push(
            EthNFT(_tokenIdCounter, 1, "eth", "erc20", 1, to, address(this))
        );
    }

    function mint(
        address _to,
        string memory _uri,
        uint256 chainId,
        uint256 amount
    ) public onlyOwner {
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _safeMint(_to, newTokenId);
        _setTokenURI(newTokenId, _uri);

        ethNFTs.push(
            EthNFT({
                tokenId: newTokenId,
                chainId: chainId,
                tick: tick,
                protocol: protocol,
                amount: amount,
                owner: _to,
                contractAddr: address(this)
            })
        );
    }

    function getNFTsByOwner(address _owner)
        public
        view
        returns (EthNFT[] memory)
    {}
}
