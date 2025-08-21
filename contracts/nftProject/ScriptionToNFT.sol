// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ScriptionToNFT is ERC721 {
    bytes32 public constant DOMAIN_NAME = keccak256("xScription");
    bytes32 public immutable DOMAIN_SEPARATOR;
        bytes32 public constant SCRIPTION_TO_NFT =
        keccak256(
            abi.encodePacked(
                "ScriptionToNFT(uint256 chainId,string tick,string protocol,address owner,uint256 amount,uint256 nonce,uint256 blockHeight)"
            )
        );
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );


    // address public trustedVerifier;

    address[] public trustedVerifier;
    mapping(address => bool) public signerAuthorized;
    mapping(address => uint256) public signerIndexes;
    address public owner;
    mapping(address => bool) public controller;
    // ower ==> tokenId
    mapping (address => uint256[]) public userTokens;

    mapping (uint256 => uint256) public tokenIndex;


    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        address[] memory _verifiers,
        address _controller,
        uint256 _scriptionLimit,
        uint256 _scriptionMintLimit,
        uint256 _blockNumberValidRange
    ) ERC721(_name, _symbol) {
        for (uint256 i = 0; i < _verifiers.length; i++) {
            address signer = _verifiers[i];
            require(!signerAuthorized[signer], "Duplicate existence");
            trustedVerifier.push(signer);
            signerAuthorized[signer] = true;
            signerIndexes[signer] = i;
        }
        controller[_controller] = true;
        owner = _owner;
        BLOCK_NUMBER_VALID_RANGE = _blockNumberValidRange;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                DOMAIN_NAME,
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        scriptionLimit = _scriptionLimit;
        scriptionMintLimit = _scriptionMintLimit;
        sigRequired = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyController() {
        require(controller[msg.sender],"Invalid controller");
        _;
    }

    // mapping(bytes => bool) public signatureReplayed;

    struct _scription{
        uint256 tokenId;
        uint256 chainID;
        string tick;
        string protocol;
        uint256 amount;
        address owner;
        address contractAddr;
    }

    uint256 public BLOCK_NUMBER_VALID_RANGE;
    uint256 public mintedScription;
    uint256 public scriptionLimit;
    uint256 public scriptionMintLimit;
    bool public sigRequired;
    mapping(address => bool) public blackList;
    mapping(uint256 => _scription) public nftToScriptions;
    mapping(address => uint256) public userMintNonce;
    mapping(address => uint256) public userMintOnBlockNumber;

    uint256 private nextTokenId = 1;

    event mintScriptionToNFTEvent(address _owner, uint256 amount, uint256 time);
    event burnScriptionNFTEvent(address _owner, uint256 balance, uint256 time);

    modifier notBlackList() {
        require(!blackList[msg.sender], "permission denied");
        _;
    }

    modifier notReachScriptionLimit() {
        require(mintedScription <= scriptionLimit, "exceed scription limit");
        _;
    }

    function _notExeceedScriptionMintLimit(
        uint256 _count
    ) internal view returns (bool) {
        require(_count <= scriptionMintLimit, "execeed scription mint limit");
        return true;
    }

    receive() external payable {}

    fallback() external {}

    function getUserMintTxNonce(address _owner) public view returns (uint256) {
        return userMintNonce[_owner];
    }

    function signatureRequiredSwitch() external onlyOwner {
        sigRequired = !sigRequired;
    }

    function addController(address _controller) external onlyOwner{
        require(!controller[_controller], "controller duplicated");
        controller[_controller] = true;
    }

    function removeController(address _controller) external onlyOwner {
        require(controller[_controller], "controller not exist");
        delete controller[_controller];
    }

    function _mintScriptionToNFT(_scription memory _data) internal {
        uint256 tokenId = nextTokenId;
        _data.tokenId = tokenId;
        _data.contractAddr = address(this);
        nftToScriptions[tokenId] = _data;
        _mint(_data.owner, tokenId);
        userTokens[_data.owner].push(nextTokenId);
        tokenIndex[nextTokenId] = userTokens[_data.owner].length - 1;
        nextTokenId += 1;
        emit mintScriptionToNFTEvent(_data.owner, _data.amount, block.timestamp);
    }

    function mintScriptionToNFT(
        _scription memory scriptionData,
        uint256 _nonce,
        uint256 _blockHeight,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external onlyController notReachScriptionLimit notBlackList {

        uint256 scriptionCount = scriptionData.amount;
        _notExeceedScriptionMintLimit(scriptionCount);
        if (sigRequired) {
            _verifyMintHash(scriptionData,_nonce,_blockHeight,v,r,s);
        }
        userMintOnBlockNumber[scriptionData.owner] = block.number;
        userMintNonce[scriptionData.owner] += 1;
        mintedScription += scriptionCount;
        // _isUserMintNonceExecuted[mintTypes.signer][mintTypes.nonce] = true;
        _mintScriptionToNFT(scriptionData);
    }

    function burnScriptionNFT(uint256 _tokenId,address _owner) external onlyController {
        require(_tokenId < nextTokenId, "none exist tokenId");
        //这行我进行了注释
        //require(_isApprovedOrOwner(msg.sender,_tokenId), "invalid NFT owner");
        _scription memory scr = nftToScriptions[_tokenId];
        delete nftToScriptions[_tokenId];
        scriptionLimit -= scr.amount;
        uint256[] storage userTokenList = userTokens[_owner];
        uint256 indexToRemove = tokenIndex[_tokenId];
        uint256 lastIndex = userTokens[_owner].length - 1;
        uint256 lastToken = userTokens[_owner][lastIndex];

        userTokenList[indexToRemove] = lastToken;

        tokenIndex[lastIndex] = indexToRemove;

        userTokenList.pop();

        delete tokenIndex[_tokenId];
        _burn(_tokenId);
        emit burnScriptionNFTEvent(
            _owner,
            scr.amount,
            block.timestamp
        );
    }

    function addSigner(address _account) external onlyOwner {
        require(!signerAuthorized[_account], "Not reentrant");
        signerIndexes[_account] = trustedVerifier.length;
        signerAuthorized[_account] = true;
        trustedVerifier.push(_account);
    }

    function setSignerAnthorization(
        address _account,
        bool _status
    ) external onlyOwner {
        signerAuthorized[_account] = _status;
    }

    function removeSigner(address _account) external onlyOwner {
        require(signerAuthorized[_account], "Non existent");
        require(
            signerIndexes[_account] < trustedVerifier.length,
            "Index out of range"
        );
        uint256 index = signerIndexes[_account];
        uint256 lastIndex = trustedVerifier.length - 1;
        if (index != lastIndex) {
            address lastAddr = trustedVerifier[lastIndex];
            trustedVerifier[index] = lastAddr;
            signerIndexes[lastAddr] = index;
        }

        delete signerAuthorized[_account];
        delete signerIndexes[_account];
    }

    function updateBlockNumberValidRange(uint256 _number) public onlyOwner {
        BLOCK_NUMBER_VALID_RANGE = _number;
    }

    function setBlackList(address _user, bool _status) public onlyOwner {
        blackList[_user] = _status;
    }

    function setScriptionLimtation(uint256 _num) public onlyOwner {
        scriptionLimit = _num;
    }

    function setScriptionMintLimatation(uint256 _num) public onlyOwner {
        scriptionMintLimit = _num;
    }


    function getUserMintTokens(address _owner) external view returns(_scription[] memory _userTokens){
        uint256[] memory tokenIdList = userTokens[_owner];
        _userTokens = new _scription[](tokenIdList.length);
        for (uint256 i = 0; i < tokenIdList.length; i++) {
            _userTokens[i] = (nftToScriptions[tokenIdList[i]]);
        }
    }

    function _verifyMintHash(
        _scription memory scriptionData,
        uint256 _nonce,
        uint256 _blockHeight,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) internal view {
        // require(!signatureReplayed[params.signature], "signature replayed");

        // signature block height must between the valid block range
        require(
            _blockHeight + BLOCK_NUMBER_VALID_RANGE >= block.number,
            "signature expired"
        );
        // Verify whether order nonce has expired

        // nonce signed in the signature must equals to the user present tx nonce stored in the contract
        if (
            _nonce < userMintNonce[scriptionData.owner] ||
            _nonce != userMintNonce[scriptionData.owner]
        ) {
            revert("NoncesInvalid");
        }

        bytes32 orderHash = buildScriptionToNFTSeparator(scriptionData,_nonce,_blockHeight);

        // Verify the validity of the signature
        bool isValid = recover(orderHash, v, r, s);
        if (!isValid) {
            revert("SignatureInvalid");
        }
        // return digest;
    }

    function _splitSignature(
        bytes memory signature
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (signature.length != 65) {
            revert("SignatureInvalid");
        }

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    function buildScriptionToNFTSeparator(
        _scription memory scriptionData,
        uint256 _nonce,
        uint256 _blockHeight
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            SCRIPTION_TO_NFT,
                            scriptionData.chainID,
                            scriptionData.tick,
                            scriptionData.protocol,
                            scriptionData.owner,
                            scriptionData.amount,
                            _nonce,
                            _blockHeight
                        )
                    )
                )
            );
    }

    function recover(
        bytes32 hash,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) public view returns (bool) {
        uint256 length = trustedVerifier.length;
        require(
            length > 0 &&
                length == v.length &&
                length == r.length &&
                length == s.length,
            "Invalid signature length"
        );
        address[] memory signatures = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            address _signer = ecrecover(hash, v[i], r[i], s[i]);
            require(signerAuthorized[_signer], "Invalid signer");
            for (uint256 j = 0; j < i; j++) {
                require(signatures[j] != _signer, "Duplicated");
            }
            signatures[i] = _signer;
        }
        return true;
    }
}
