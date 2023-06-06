// A contract to track the modifications/maintenance of a vehicle
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// imports for ERC20 payment
import "./IERC20.sol";
import "./SafeERC20.sol";

// Enum to store user types
enum UserType {
    Unregistered,
    SuperAdmin,
    AutoShop,
    CarDealer,
    CarOwner
}

// Struct to store the details of subscription payment
struct SubscriptionPayment {
    address user;
    uint256 paymentTime;
    uint256 paymentAmount;
    uint256 subscriptionExpiry;
}

// Struct to store the details of a vehicle
struct Vehicle {
    string VIN;
    string brand;
    string model;
    string color;
    string engineNumber;
    string chassisNumber;
    string ownerName;
}

// Struct to store the details of auto shop / car dealer
struct Shop {
    string ownerNames;
    string name;
    string location;
    string contactNumber;
    string email;
    string website;
    string logo;
    string[] services;
    uint256[] subscriptionReceipts;
    address payable shopWallet;
    string officialID;
}

// Struct to manage the dashboard of an auto shop / car dealer
struct Dashboard {
    uint256 totalCustomers;
    uint256 totalRevenue;
    uint256 completedServices;
    string[] vehicleVINs;
}

// Struct to store the details of a car owner
struct Owner {
    string name;
    string contactNumber;
    string email;
    string officialID;
    string[] vehicleVINs;
    address payable ownerWallet;
}

// Struct to store the details of a vehicle modification
struct Modification {
    string VIN;
    string modificationType;
    string modificationDescription;
    uint256 modificationTime;
    uint256 modificationCost;
    uint256 modificationLocation;
    address serviceProvider;
}

contract vehicleModificationTracker {
    // import SafeERC20 library
    using SafeERC20 for IERC20;

    // Owner of the contract
    address public owner;

    // Token used for payment
    IERC20 public secondaryToken;

    // Manage the payment options
    uint8 public paymentOption = 1; // 0 - ERC20, 1 - ETH (default)

    // Fee for the subscription
    uint256 public ethFee = 0.01 ether;
    uint256 public tokenFee = 100 * 10 ** 18;

    // Analytics
    uint256 public totalPaymentEth;
    uint256 public totalPaymentToken;
    mapping(address => uint256) public totalPaymentEthByUser;
    mapping(address => uint256) public totalPaymentTokenByUser;

    // mapping user address to subscription payment details
    mapping(address => SubscriptionPayment) public subscriptionPayments;

    // mapping user address to user type
    mapping(address => UserType) public userTypes;

    // mapping user address to auto shop details
    mapping(address => Shop) public shops;

    // modifier to check if the user is a super admin
    modifier onlySuperAdmin() {
        require(
            userTypes[msg.sender] == UserType.SuperAdmin,
            "Only super admin can call this function"
        );
        _;
    }

    // modifier to check if the user is an auto shop
    modifier onlyAutoShop() {
        require(
            userTypes[msg.sender] == UserType.AutoShop,
            "Only auto shop can call this function"
        );
        _;
    }

    // modifier to check if the user is a car dealer
    modifier onlyCarDealer() {
        require(
            userTypes[msg.sender] == UserType.CarDealer,
            "Only car dealer can call this function"
        );
        _;
    }

    // modifier to check if the user is a car owner
    modifier onlyCarOwner() {
        require(
            userTypes[msg.sender] == UserType.CarOwner,
            "Only car owner can call this function"
        );
        _;
    }

    // modifier to check if the user is a super admin or auto shop or car dealer
    modifier onlySuperAdminOrAutoShopOrCarDealer() {
        require(
            userTypes[msg.sender] == UserType.SuperAdmin ||
                userTypes[msg.sender] == UserType.AutoShop ||
                userTypes[msg.sender] == UserType.CarDealer,
            "Wallet not authorized to call this function"
        );
        _;
    }

    // modifier to check if the user is a super admin or car owner
    modifier onlySuperAdminOrCarOwner() {
        require(
            userTypes[msg.sender] == UserType.SuperAdmin ||
                userTypes[msg.sender] == UserType.CarOwner,
            "Only super admin or car owner can call this function"
        );
        _;
    }

    // modifier to check if auto shop or car dealer has active subscription
    modifier onlyActiveSubscription() {
        require(
            subscriptionPayments[msg.sender].subscriptionExpiry >=
                block.timestamp,
            "Your subscription has expired. Please renew your subscription to continue using the service"
        );
        _;
    }

    // modifier to check if the car dealer / auto shop is registered
    modifier onlyRegistered() {
        require(
            userTypes[msg.sender] == UserType.AutoShop ||
                userTypes[msg.sender] == UserType.CarDealer,
            "You are not registered"
        );
        _;
    }

    // Constructor
    constructor(address _tokenAddress) {
        owner = msg.sender;
        userTypes[msg.sender] = UserType.SuperAdmin;
        secondaryToken = IERC20(_tokenAddress);
    }

    // Function to pay for the subscription
    function payForSubscription() external payable onlyRegistered {
        require(
            subscriptionPayments[msg.sender].subscriptionExpiry == 0,
            "You already have an active subscription"
        );
        if (paymentOption == 0) {
            require(
                msg.value == 0,
                "You have selected ERC20 as payment option. Please pay using ERC20 tokens"
            );
            secondaryToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenFee
            );
            totalPaymentToken = totalPaymentToken + tokenFee;
            totalPaymentTokenByUser[msg.sender] =
                totalPaymentTokenByUser[msg.sender] +
                tokenFee;
        } else {
            require(
                msg.value == ethFee,
                "You have selected ETH as payment option. Please pay using ETH"
            );
            totalPaymentEth = totalPaymentEth + ethFee;
            totalPaymentEthByUser[msg.sender] =
                totalPaymentEthByUser[msg.sender] +
                ethFee;
        }
        subscriptionPayments[msg.sender] = SubscriptionPayment(
            msg.sender,
            block.timestamp,
            msg.value,
            block.timestamp + 365 days
        );
    }

    // Function to pay for the subscription in advance

    // Allow smart contract to receive ETH
    receive() external payable {}
}
