// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract AirToken is ERC20 {

  mapping(address => bool) public _processedAirdrop;

  address public _admin;
  address[] public _airdropAddressList;
  uint256[] public _airdropAmountList;
  uint256 public _maxAirdropAmount;
  uint256 public _currentAirdropAmount;

  event AirdropProcessed(address _recipient, uint256 _amount, uint256 _date);

  constructor() ERC20("TokenX", "TKX") {
    _mint(msg.sender, 1000 * 10**18);
    _admin = msg.sender;
    _maxAirdropAmount = (1 * totalSupply()) / 100; // Max amount for Air drop is allocatied to 1% of total supply.
  }

  // This will be used on functions that should be run by only admin
  modifier onlyAdmin() {
    require(msg.sender == _admin, "Only admin can perform this action");
    _;
  }

  // Function to Change the admin
  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0), "Address cannot be 0");

    _admin = _newAdmin;
  }

  // Allowing admin to add specific address for the Airdrop.
  function addAddressForAirDrop(address _address, uint256 _amount)
    public
    onlyAdmin
  {
    require(_amount > 0, "Amount cannot be less than 1");
    _airdropAddressList.push(_address);
    _airdropAmountList.push(_amount);
  }

  // This function will let the admin to remove specific address for the Airdrop.
  function removeAddressForAirDrop(address _address) external onlyAdmin {
    require(_address != address(0), "Address cannot be 0");

    for (uint256 i = 0; i < _airdropAddressList.length; i++) {
      if (_address == _airdropAddressList[i]) {
        _airdropAddressList[i] = _airdropAddressList[
          _airdropAddressList.length - 1
        ];
        _airdropAmountList[i] = _airdropAmountList[
          _airdropAmountList.length - 1
        ];
        _airdropAddressList.pop();
        _airdropAmountList.pop();
      }
    }
  }

  // This function will clear the existing Airdrop List as well as Amount List
  function clearAirdropList() external onlyAdmin {
    delete _airdropAddressList;
    delete _airdropAmountList;
  }

  // This function will help the admin to mint token
  function mint(address to, uint256 amount) external onlyAdmin {
    _mint(to, amount);
  }

  // Anyone can burn thier own token if required.
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function claimToken(address _recipient) external {
    uint256 index;
    uint8 flag = 1;
    require(
      _processedAirdrop[_recipient] == false,
      "Airdrop already Processed for this address"
    );

    for (uint256 i = 0; i < _airdropAddressList.length; i++) {
      if (_airdropAddressList[i] == _recipient) {
        index = i;
        flag = 0;
        break;
      }
    }

    require(
      flag == 0 || _airdropAddressList[index] == _recipient,
      "This address is not eligible for the airdrop"
    );

    require(
      _currentAirdropAmount + _airdropAmountList[index] <= _maxAirdropAmount,
      "Airdropped 100% of the allocated amount"
    );

    _processedAirdrop[_recipient] = true;
    _currentAirdropAmount += _airdropAmountList[index];
    _transfer(_admin, _recipient, _airdropAmountList[index]);
    emit AirdropProcessed(
      _recipient,
      _airdropAmountList[index],
      block.timestamp
    );
  }

  function getMaxAirdropAmount() external view returns (uint256) {
    return _maxAirdropAmount;
  }

  function getCurrentAirdropAmount() external view returns (uint256) {
    return _currentAirdropAmount;
  }

  function getWhitelistedAddress() external view returns (address[] memory) {
    return _airdropAddressList;
  }

  function getAllocatedAmount() external view returns (uint256[] memory) {
    return _airdropAmountList;
  }

  function getProcessedAirdrop(address _address) external view returns (bool) {
    return _processedAirdrop[_address];
  }
}