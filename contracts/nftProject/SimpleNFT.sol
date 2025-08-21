// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleNFT is ERC721, Ownable {
    using SafeERC20 for IERC20;

    uint256 private nextTokenId = 1;
    uint256 public maxSupply = 10000;
    uint256 public mintPrice = 0.0001 ether;
    uint256 public maxMintPerAddress = 10;
    WrappedNFTInfo[] public wrappedNFTList; // ✅ 存储所有已包装的 NFT 信息

    mapping(address => uint256) public mintedCount;
    IERC20 public immutable wrappedToken;
    // ✅ 用于记录每个NFT中包裹的ERC20信息
    struct WrappedERC20 {
        address token;     // ERC20地址
        uint256 amount;    // 包装的数量
    }
// ✅ 固定包装代币（由构造函数传入）
   // ✅ 用于返回的包装 NFT 信息
struct WrappedNFTInfo {
    uint256 tokenId;
    uint256 amount;
}


    // ✅ 每个NFT包装的代币数量
    mapping(uint256 => uint256) public wrappedAmount;
    mapping(uint256 => WrappedERC20) public wrappedAssets;

    constructor(address _wrappedToken) ERC721("SimpleNFT", "SNFT") Ownable(msg.sender) {
    wrappedToken = IERC20(_wrappedToken); // ✅ 正确赋值
}
    // ✅ 基础 ETH mint，不涉及包装
    function mint() public payable {
        require(nextTokenId <= maxSupply, "Max supply reached");
        require(msg.value >= mintPrice, "Insufficient payment");
        require(mintedCount[msg.sender] < maxMintPerAddress, "Max mint per address reached");

        uint256 tokenId = nextTokenId++;
        mintedCount[msg.sender]++;
        _mint(msg.sender, tokenId);
    }

    // ✅ 包装 ERC20 成 NFT（固定代币地址）
    function wrap(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");

        // 转账 ERC20 到合约
        wrappedToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 tokenId = nextTokenId++;
        wrappedAmount[tokenId] = amount;
 // ✅ 添加到数组中
    wrappedNFTList.push(WrappedNFTInfo({
        tokenId: tokenId,
        amount: amount
    }));
        _mint(msg.sender, tokenId);
    }

    // ✅ 拆包：销毁 NFT，返还代币
    function unwrap(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");

        uint256 amount = wrappedAmount[tokenId];
        require(amount > 0, "Nothing wrapped");

        delete wrappedAmount[tokenId];
        _burn(tokenId);

        wrappedToken.safeTransfer(msg.sender, amount);
          // ✅ 从 wrappedNFTList 中移除对应 tokenId 的项（线性查找后移除）
    for (uint256 i = 0; i < wrappedNFTList.length; i++) {
        if (wrappedNFTList[i].tokenId == tokenId) {
            // 将最后一个元素移到当前位置，然后 pop
            wrappedNFTList[i] = wrappedNFTList[wrappedNFTList.length - 1];
            wrappedNFTList.pop();
            break;
        }
    }
    }

    // ✅ 查询包装信息
    function getWrappedAmount(uint256 tokenId) external view returns (uint256) {
        return wrappedAmount[tokenId];
    }

  function getAllWrappedNFTs() public view returns (WrappedNFTInfo[] memory) {
        uint256 total = nextTokenId - 1;
        uint256 count = 0;

        for (uint256 i = 1; i <= total; i++) {
            if (wrappedAmount[i] > 0) {
                count++;
            }
        }

        WrappedNFTInfo[] memory result = new WrappedNFTInfo[](count);
        uint256 index = 0;

        for (uint256 i = 1; i <= total; i++) {
            if (wrappedAmount[i] > 0) {
                result[index] = WrappedNFTInfo({
                    tokenId: i,
                    amount: wrappedAmount[i]
                });
                index++;
            }
        }
         return result;
}
        
    // ✅ 批量 mint（ETH）
    function mintBatch(uint256 amount) public payable {
        require(amount > 0 && amount <= 10, "Invalid amount");
        require(nextTokenId + amount - 1 <= maxSupply, "Max supply reached");
        require(msg.value >= mintPrice * amount, "Insufficient payment");
        require(mintedCount[msg.sender] + amount <= maxMintPerAddress, "Max mint per address reached");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = nextTokenId++;
            _mint(msg.sender, tokenId);
        }
        mintedCount[msg.sender] += amount;
    }

    // ✅ Owner 免费 mint
    function ownerMint(address to, uint256 amount) public onlyOwner {
        require(amount > 0, "Invalid amount");
        require(nextTokenId + amount - 1 <= maxSupply, "Max supply reached");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = nextTokenId++;
            _mint(to, tokenId);
        }
    }

    // ✅ 设置参数相关函数
    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintPerAddress(uint256 _maxMint) public onlyOwner {
        maxMintPerAddress = _maxMint;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    // ✅ URI 相关
    string private baseTokenURI;

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        if (bytes(baseTokenURI).length == 0) {
            return "";
        }

        return string(abi.encodePacked(baseTokenURI, _toString(tokenId), ".json"));
    }

    function totalSupply() public view returns (uint256) {
        return nextTokenId - 1;
    }

    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    // 工具函数
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
