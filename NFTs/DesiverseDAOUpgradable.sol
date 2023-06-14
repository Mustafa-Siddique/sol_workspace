// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/proxy/utils/Initializable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/structs/EnumerableSetUpgradeable.sol";

struct VoucherBlock {
    string Voucher;
    uint256 Vouchertype;
    bool Status;
}

contract DesiverseDao is Initializable, ERC1155Upgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    EnumerableSetUpgradeable.AddressSet private _approvedMinters;
    mapping(address => bool) private _tokenOwners;
    mapping(address => mapping(uint256 => uint256)) private _unlockTimes;
    mapping(uint256 => bool) private _lockedTokens;
    mapping(uint256 => address) private _founder;
    mapping(uint256 => uint256) private _voucherCount;
    mapping(string => bool) private _voucherStatus;
    mapping(string => uint256) private _voucherCodes;
    mapping(uint256 => string) private _allCodes;
    address private _owner;
    uint256 private _maxSupply;
    uint256 private _lockedDays;
    uint256 private _tokenId;
    uint256 private founderCount;
    uint256 private price;
    uint256 private codeCounter;

    // Events
    event TokenLocked(uint256 tokenId, uint256 unlockTime);
    event TokenUnlocked(uint256 tokenId);

    // Function to initialize the contract
    function initialize() public initializer {
        __ERC1155_init(
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/QmNvDeMQEmwNU7GFzQM8Q7qzKH1rvTF5eyW9yEqB2NFahr/",
                    _tokenId
                )
            )
        );
        _owner = msg.sender;
        price = 0.09 ether;
        _maxSupply = 1111;
    }

    // Modifiers
    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Only the owner can perform this operation"
        );
        _;
    }

    modifier approval(address account) {
        if (!isApprovedForAll(_owner, account)) {
            _setApprovalForAll(_owner, account, true);
        }
        _;
    }

    modifier onlyMinter() {
        require(
            EnumerableSetUpgradeable.contains(_approvedMinters, msg.sender),
            "Only approved minters can perform this operation"
        );
        _;
    }

    // ------------------ Write Functions ------------------

    // Function to set the base URI
    function setNewURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // Function to mint NFT
    function mint(address account) public onlyOwner {
        require(!_lockedTokens[_tokenId], "Token is locked");
        _mint(account, _tokenId, 1, "");
        _tokenId++;
    }

    // Function to mint NFT batch
    function mintBatch(address account, uint256 amount) public onlyOwner {
        require(!_lockedTokens[_tokenId], "Token is locked");
        _mint(account, _tokenId, amount, "");
        _tokenId++;
    }

    // Function to mint all supply at once to owner
    function mintAll() public onlyOwner {
        _mint(_owner, _tokenId, _maxSupply, "");
        _tokenId++;
    }

    // Function to add voucher codes
    function addVouchers(
        string[] memory codes,
        uint256[] memory voucherType
    ) public onlyOwner {
        require(codes.length < 250, "Max voucher supply is 250");
        require(codes.length == voucherType.length, "Arrays length mismatch");
        for (uint256 i = 0; i < codes.length; i++) {
            _voucherCodes[codes[i]] = voucherType[i];
            codeCounter++;
            _allCodes[codeCounter] = codes[i];
        }
    }

    // Function to set locked days
    function setLockedDays(uint256 daysLocked) public onlyOwner {
        _lockedDays = daysLocked;
    }

    // Function to set max supply
    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        _maxSupply = maxSupply;
    }

    // Function to buy NFT
    function buy(
        address account,
        uint256 id,
        string memory voucherCode
    ) public payable approval(account) {
        require(founderCount <= _maxSupply, "No more token for buy");
        require(id <= _maxSupply, "Token id is not valid");

        require(!_lockedTokens[id], "Token is locked");
        require(!_voucherStatus[voucherCode], "Voucher Already Used");
        require(_voucherCodes[voucherCode] <= 3, "Wrong woucher");
        require(
            !_tokenOwners[msg.sender],
            "You are not allowed to buy more token, Only one time buy allowed"
        );
        uint256 discount = 0;
        if (bytes(voucherCode).length > 0) {
            uint256 voucherType = _voucherCodes[voucherCode];
            require(voucherType > 0, "Invalid voucher code");
            require(
                _voucherCount[1] <= 50,
                "No more voucher available for this type"
            );
            require(
                _voucherCount[2] <= 100,
                "No more voucher available for this type"
            );

            require(
                _voucherCount[3] <= 100,
                "No more voucher available for this type"
            );
            if (voucherType == 1) {
                discount = price;
            } else if (voucherType == 2) {
                discount = (price * 15) / 100;
            } else if (voucherType == 3) {
                discount = (price * 50) / 100;
            }
        }
        require(msg.value >= price - discount, "Insufficient funds");
        safeTransferFrom(_owner, account, id, 1, "");
        founderCount++;
        _founder[founderCount] = account;
        _lockedTokens[id] = true;
        _voucherCount[_voucherCodes[voucherCode]]++;
        _voucherStatus[voucherCode] = true;
        _tokenOwners[msg.sender] = true;
        // Set the unlock time for this token and user
        uint256 unlockingTime = block.timestamp +
            (_lockedDays * 1 days) +
            1 days;
        _unlockTimes[msg.sender][id] = unlockingTime;

        emit TokenLocked(id, unlockingTime);
    }

    // Function to buy only
    function buyOnly(
        address account,
        uint256 id
    ) public payable approval(account) {
        require(founderCount <= _maxSupply, "No more token for buy");
        require(id <= _maxSupply, "Token id is not valid");
        require(!_lockedTokens[id], "Token is locked");
        require(
            !_tokenOwners[msg.sender],
            "You are not allowed to buy more token, Only one time buy allowed"
        );

        require(msg.value >= price, "Insufficient funds");
        safeTransferFrom(_owner, account, id, 1, "");
        founderCount++;
        _founder[founderCount] = account;
        _lockedTokens[id] = true;
        _tokenOwners[msg.sender] = true;

        // Set the unlock time for this token and user
        uint256 unlockingTime = block.timestamp +
            (_lockedDays * 1 days) +
            1 days;
        _unlockTimes[msg.sender][id] = unlockingTime;

        emit TokenLocked(id, unlockingTime);
    }

    // Function to unlock token
    function unlockToken(uint256 tokenId) public onlyOwner {
        require(_lockedTokens[tokenId], "Token is not locked");
        require(
            block.timestamp >= unlockTime(tokenId),
            "Token is still locked"
        );
        _lockedTokens[tokenId] = false;
        emit TokenUnlocked(tokenId);
    }

    // Function to get voucher codes
    function getVouchers()
        public
        view
        onlyOwner
        returns (VoucherBlock[] memory)
    {
        uint256 numCodes = codeCounter;
        VoucherBlock[] memory CodeRecord = new VoucherBlock[](numCodes);

        for (uint256 i = 1; i <= numCodes; i++) {
            string memory vcode = _allCodes[i];
            uint256 vtype = _voucherCodes[vcode];
            bool vstate = _voucherStatus[vcode];
            VoucherBlock memory coderecord = VoucherBlock(vcode, vtype, vstate);
            CodeRecord[i - 1] = coderecord;
        }
        return CodeRecord;
    }

    // Function to check balance
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual override returns (uint256) {
        return super.balanceOf(account, id);
    }

    // Function to check balance batch
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        return super.balanceOfBatch(accounts, ids);
    }

    // Function to get unlock time
    function unlockTime(uint256 tokenId) public view returns (uint256) {
        require(_lockedTokens[tokenId], "Token is not locked");
        return block.timestamp + (_lockedDays * 1 days);
    }

    // Function to get token lock status
    function isTokenUnlocked(uint256 tokenId) public view returns (bool) {
        return
            !_lockedTokens[tokenId] ||
            _unlockTimes[msg.sender][tokenId] <= block.timestamp;
    }

    // Function to get max supply
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }
}
