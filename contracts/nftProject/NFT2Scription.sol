// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT2Scription is ERC721 {
    address public owner;
    
    constructor() ERC721("MyNFT", "MyNFT"){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"not owner");
        _;
    }

    // 保留的存储结构
    mapping(address => bytes32[]) public _scriptions;
    mapping(uint256 => bytes32[]) public nftToScriptions;
    mapping(bytes32 => bool) public mintedScriptions;
    
    uint256 private nextTokenId = 1;

    // 保留的事件
    event mintScriptionToNFTEvent(
        address _owner,
        bytes32[] scriptions,
        uint256 time
    );
    event burnScriptionNFTEvent(
        address _owner,
        bytes32[] scriptions,
        uint256 time
    );

    // 保留的检查函数
    function _isScriptionDuplicated(address _addr, bytes32 _txHash)
        public
        view
        returns (bool)
    {
        bytes32[] memory hashList = _scriptions[_addr];
        for (uint256 i = 0; i < hashList.length; i++) {
            if (hashList[i] == _txHash) {
                return true;
            }
        }
        return false;
    }

    function _isScriptionMintedToNFT(bytes32[] memory scriptions)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < scriptions.length; i++) {
            if (mintedScriptions[scriptions[i]]) {
                return true;
            }
        }
        return false;
    }

    function _isScriptionExist(address _owner, bytes32 scriptions)
        public
        view
        returns (bool)
    {
        bytes32[] memory _txHashes = _scriptions[_owner];
        bool _exists;
        for (uint256 i = 0; i < _txHashes.length; i++) {
            if (_txHashes[i] == scriptions) {
                _exists = true;
            }
        }
        return _exists;
    }

    receive() external payable {}

    // 保留的 fallback 函数，用于记录 scription
    fallback() external {
        if (msg.data.length == 32) {
            bytes32 _txHash;
            assembly {
                _txHash := calldataload(0)
            }
            bool _isDuplicated = _isScriptionDuplicated(msg.sender, _txHash);
            require(
                !_isDuplicated,
                "scription already recorded for this sender"
            );
            _scriptions[msg.sender].push(_txHash);
        }
        return;
    }

    // 简化的 mint 函数 - 直接调用，无需签名
    function mintScriptionToNFT(bytes32[] memory scriptions) public {
        bool _minted = _isScriptionMintedToNFT(scriptions);
        require(!_minted, "minted before");
        
        bool _exist;
        for (uint256 i = 0; i < scriptions.length; i++) {
            _exist = _isScriptionExist(msg.sender, scriptions[i]);
            require(_exist, "scription doesn't exist");
        }
        
        uint256 tokenId = nextTokenId;
        nftToScriptions[tokenId] = scriptions;
        
        for (uint256 i = 0; i < nftToScriptions[tokenId].length; i++) {
            mintedScriptions[nftToScriptions[tokenId][i]] = true;
        }
        
        _mint(msg.sender, tokenId);
        nextTokenId += 1;
        emit mintScriptionToNFTEvent(msg.sender, scriptions, block.timestamp);
    }

    // 保留的 burn 函数
    function burnScriptionNFT(uint256 _tokenId) public {
        require(_tokenId < nextTokenId, "none exist tokenId");
        require(ownerOf(_tokenId) == msg.sender, "invalid NFT owner");
        
        bytes32[] memory scriptions = nftToScriptions[_tokenId];
        delete nftToScriptions[_tokenId];
        
        for (uint256 i = 0; i < scriptions.length; i++) {
            mintedScriptions[scriptions[i]] = false;
        }
        
        _burn(_tokenId);
        emit burnScriptionNFTEvent(msg.sender, scriptions, block.timestamp);
    }

    // 新增：获取用户的 scriptions
    function getUserScriptions(address user) public view returns (bytes32[] memory) {
        return _scriptions[user];
    }

    // 新增：获取 NFT 对应的 scriptions
    function getNFTScriptions(uint256 tokenId) public view returns (bytes32[] memory) {
        return nftToScriptions[tokenId];
    }

    // 新增：获取下一个 tokenId
    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }
}