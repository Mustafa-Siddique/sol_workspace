// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Upgradable.sol";
import "./Initializable.sol";
import "./EnumerableSetUpgradeable.sol";

struct Voucher {
    string Voucher;
    uint256 Vouchertype;
    bool Status;
    uint256 Count;
}

contract DesiverseDao is Initializable, ERC1155Upgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    EnumerableSetUpgradeable.AddressSet private _approvedMinters;
    mapping(address => bool) private _tokenOwners;
    mapping(address => mapping(uint256 => uint256)) private _unlockTimes;
    mapping(uint256 => bool) private _lockedTokens;
    mapping(uint256 => address) private _founder;
    mapping(string => Voucher) private _vouchers;
    mapping(uint256 => string) private _allCodes;
    address public _owner;
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
        _lockedDays = 30;
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
        _mint(account, _tokenId, 1, "");
        _tokenId++;
    }

    // Function to mint NFT batch
    function mintBatch(address account, uint256 amount) public onlyOwner {
        _mint(account, _tokenId, amount, "");
        _tokenId++;
    }

    // Function to mint all supply at once to owner
    function mintAll() public onlyOwner {
        _mint(_owner, _tokenId, _maxSupply, "");
        _tokenId++;
    }

    // Function to add voucher code and type with count
    function addVoucher(
        string memory voucherCode,
        uint256 voucherType,
        uint256 count
    ) public onlyOwner {
        require(bytes(voucherCode).length > 0, "Voucher code is required");
        require(voucherType > 0, "Voucher type is required");
        require(voucherType > 0 && voucherType < 4, "Invalid voucher type");
        require(
            _vouchers[voucherCode].Vouchertype == 0,
            "Voucher code already exist"
        );
        Voucher memory voucher = Voucher(
            voucherCode,
            voucherType,
            false,
            count
        );
        _vouchers[voucherCode] = voucher;
        codeCounter++;
        _allCodes[codeCounter] = voucherCode;
    }

    // Function to set locked days
    function setLockedDays(uint256 daysLocked) public onlyOwner {
        _lockedDays = daysLocked;
    }

    // Function to set max supply
    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        _maxSupply = maxSupply;
    }

    // Function to buy NFT with voucher code where voucher type 1 is 15% discount, 2 is 50% discount and 3 is 100% discount
    function buy(
        address account,
        uint256 id,
        string memory voucherCode
    ) public payable approval(account) {
        require(founderCount <= _maxSupply, "No more token for buy");
        require(id <= _maxSupply, "Token id is not valid");
        require(
            !_tokenOwners[msg.sender],
            "You can't have more than one token"
        );
        require(
            _vouchers[voucherCode].Vouchertype > 0 &&
                _vouchers[voucherCode].Vouchertype < 4,
            "Invalid voucher code"
        );
        require(_vouchers[voucherCode].Count > 0, "Cannot redeem voucher");
        uint256 _price;
        if (_vouchers[voucherCode].Vouchertype == 1) {
            _price = (price * 85) / 100;
            require(msg.value == _price, "Eth Invalid");
        } else if (_vouchers[voucherCode].Vouchertype == 2) {
            _price = (price * 50) / 100;
            require(msg.value == _price, "Eth Invalid");
        } else if (_vouchers[voucherCode].Vouchertype == 3) {
            _price = 0;
            require(msg.value == _price, "Eth Invalid");
        }
        safeTransferFrom(_owner, account, id, 1, "");
        founderCount++;
        _founder[founderCount] = account;
        _lockedTokens[id] = true;
        _tokenOwners[msg.sender] = true;
        _vouchers[voucherCode].Count--;

        // Set the unlock time for this token and user after 30 days
        uint256 unlockingTime = block.timestamp +
            (_lockedDays * 1 days) +
            1 days;

        emit TokenLocked(id, unlockingTime);
    }

    // Function to buy only
    function buyOnly(
        address account,
        uint256 id
    ) public payable approval(account) {
        require(founderCount <= _maxSupply, "No more token for buy");
        require(id <= _maxSupply, "Token id is not valid");
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

        // Set the unlock time for this token and user after 30 days
        uint256 unlockingTime = block.timestamp +
            (_lockedDays * 1 days) +
            1 days;

        emit TokenLocked(id, unlockingTime);
    }

    // Function for safe transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(isTokenUnlocked(id), "Token is locked");
        super.safeTransferFrom(from, to, id, amount, data);
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
    function getVoucherCodes() public view onlyOwner returns (string[] memory) {
        string[] memory codes = new string[](codeCounter);
        for (uint256 i = 0; i < codeCounter; i++) {
            codes[i] = _allCodes[i + 1];
        }
        return codes;
    }

    // Function to get NFT price
    function getPrice() public view returns (uint256) {
        return price;
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

    // Function to check voucher code and return price
    function checkVoucherCode(
        string memory voucherCode
    ) public view returns (uint256) {
        require(
            _vouchers[voucherCode].Vouchertype > 0 &&
                _vouchers[voucherCode].Vouchertype < 4,
            "Invalid voucher code"
        );
        require(_vouchers[voucherCode].Count > 0, "Voucher Expired");
        uint256 _price;
        if (_vouchers[voucherCode].Vouchertype == 1) {
            _price = (price * 85) / 100;
        } else if (_vouchers[voucherCode].Vouchertype == 2) {
            _price = (price * 50) / 100;
        } else if (_vouchers[voucherCode].Vouchertype == 3) {
            _price = 0;
        }
        return _price;
    }

    // Function to get max supply
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    // Transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "New owner address cannot be zero address"
        );
        _owner = newOwner;
    }

    // Renounce ownership
    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }
}
