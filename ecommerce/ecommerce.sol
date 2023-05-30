// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC20.sol";

// Struct to store details of product
struct Product {
    uint256 id;
    string name;
    uint256 price;
    uint256 quantity;
    string description;
    string image;
    uint256 status;
    string category;
}

// Struct to store user details in relation with wallet address
struct User {
    uint256 id;
    string name;
    string phone;
    string _address;
    uint256[] orderIds;
    address payable walletAddress;
}

// Struct to store order details with product and quantity relation
struct Order {
    uint256 id;
    uint256[] productIds;
    uint256[] quantities;
    uint256 price;
    uint256 status;
    uint256 dateTime;
}

// Struct to store coupon details
struct Coupon {
    uint256 id;
    string name;
    uint256 discountPercentage;
    uint256 status;
}

contract carewellEcommercePlatform {
    // Carewell Token Contract
    IERC20 public carewellToken;
    address payable public owner;

    // Cost of 1 CAREWELL Token
    uint256 public cost = 1 * 10 ** 18;

    // Modifier to check if the caller is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // Glopbal counter for products, users, orders and coupons
    uint256 public productCount = 0;
    uint256 public userCount = 0;
    uint256 public orderCount = 0;
    uint256 public couponCount = 0;

    // ------------------- Mappings -------------------

    // Mapping to store product details with product id
    mapping(uint256 => Product) public products;

    // Mapping to store user details with user id
    mapping(uint256 => User) users;

    // Mapping to store order details with order id
    mapping(uint256 => Order) orders;

    // Mapping to store coupon details with coupon id
    mapping(uint256 => Coupon) public coupons;

    // ------------------- Setters -------------------

    // Function to add product
    function addProduct(
        string memory _name,
        uint256 _price,
        uint256 _quantity,
        string memory _description,
        string memory _image,
        string memory _category
    ) public onlyOwner {
        require(bytes(_name).length > 0, "Name should not be empty or null.");
        require(_price > 0, "Price should be greater than 0.");
        require(_quantity > 0, "Quantity should be greater than 0.");
        require(
            bytes(_description).length > 0,
            "Description should not be empty or null."
        );
        require(bytes(_image).length > 0, "Image should not be empty or null.");
        require(
            bytes(_category).length > 0,
            "Category should not be empty or null."
        );

        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _price,
            _quantity,
            _description,
            _image,
            1,
            _category
        );
    }

    // Function to add user
    function addUser(
        string memory _name,
        string memory _phone,
        string memory _address
    ) public {
        require(bytes(_name).length > 0, "Name should not be empty or null.");
        require(bytes(_phone).length > 0, "Phone should not be empty or null.");
        require(
            bytes(_address).length > 0,
            "Address should not be empty or null."
        );
        require(
            msg.sender != address(0),
            "Wallet address should not be empty or null."
        );
        require(msg.sender != owner, "Owner cannot be added as user.");

        userCount++;
        users[userCount] = User(
            userCount,
            _name,
            _phone,
            _address,
            new uint256[](0),
            payable(msg.sender)
        );
    }

    // Function to place order by user while calculating price with product id automatically
    function initiateOrder(
        uint256[] memory _productIds,
        uint256[] memory _quantities,
        uint256 _couponId
    ) public payable {
        require(_productIds.length > 0, "Product ids should not be empty.");
        require(_quantities.length > 0, "Quantities should not be empty.");
        require(
            _productIds.length == _quantities.length,
            "Product ids and quantities should be equal."
        );

        uint256 _price = 0;
        for (uint256 i = 0; i < _productIds.length; i++) {
            require(
                products[_productIds[i]].status == 1,
                "Product should be active."
            );
            require(
                products[_productIds[i]].quantity >= _quantities[i],
                "Product quantity should be greater than or equal to order quantity."
            );
            _price += products[_productIds[i]].price * _quantities[i];
        }

        // Discount calculation using coupon id
        if (_couponId > 0) {
            require(coupons[_couponId].status == 1, "Coupon should be active.");
            _price =
                _price -
                ((_price * coupons[_couponId].discountPercentage) / 100);
        }

        // transfer carewell tokens to owner
        carewellToken.transferFrom(msg.sender, owner, _price / cost);

        orderCount++;
        orders[orderCount] = Order(
            orderCount,
            _productIds,
            _quantities,
            _price,
            1,
            block.timestamp
        );
        users[userCount].orderIds.push(orderCount);
    }

    // Function to add coupon
    function createCoupon(
        string memory _name,
        uint256 _discountPercentage
    ) public onlyOwner {
        require(bytes(_name).length > 0, "Name should not be empty or null.");
        require(
            _discountPercentage > 0,
            "Discount percentage should be greater than 0."
        );

        couponCount++;
        coupons[couponCount] = Coupon(
            couponCount,
            _name,
            _discountPercentage,
            1
        );
    }

    // ------------------- Getters -------------------

    // Function to get product details by product id
    function getProduct(
        uint256 _productId
    )
        public
        view
        returns (
            uint256 id,
            string memory name,
            uint256 price,
            uint256 quantity,
            string memory description,
            string memory image,
            uint256 status,
            string memory category
        )
    {
        require(
            _productId > 0 && _productId <= productCount,
            "Product id should be greater than 0 and less than or equal to product count."
        );

        Product memory _product = products[_productId];
        return (
            _product.id,
            _product.name,
            _product.price,
            _product.quantity,
            _product.description,
            _product.image,
            _product.status,
            _product.category
        );
    }

    // Function to get user details by user wallet address
    function getUser(
        address _walletAddress
    )
        public
        view
        returns (
            uint256 id,
            string memory name,
            string memory phone,
            string memory _address,
            uint256[] memory orderIds,
            address payable walletAddress
        )
    {
        require(
            _walletAddress != address(0),
            "Wallet address should not be empty or null."
        );
        require(
            msg.sender == owner || msg.sender == _walletAddress,
            "Only owner and user can get user details."
        );

        for (uint256 i = 1; i <= userCount; i++) {
            if (users[i].walletAddress == payable(_walletAddress)) {
                User memory _user = users[i];
                return (
                    _user.id,
                    _user.name,
                    _user.phone,
                    _user._address,
                    _user.orderIds,
                    _user.walletAddress
                );
            }
        }
    }

    // Function to get order details by order id
    function getOrder(
        uint256 _orderId
    )
        public
        view
        returns (
            uint256 id,
            uint256[] memory productIds,
            uint256[] memory quantities,
            uint256 price,
            uint256 status,
            uint256 dateTime
        )
    {
        require(
            _orderId > 0 && _orderId <= orderCount,
            "Order id should be greater than 0 and less than or equal to order count."
        );
        // Check if buyer/owner is calling this function
        for (uint256 i = 0; i <= userCount; i++) {
            if (users[i].walletAddress == payable(msg.sender)) {
                for (uint256 j = 0; j < users[i].orderIds.length; j++) {
                    if (users[i].orderIds[j] == _orderId) {
                        break;
                    }
                    if (j == users[i].orderIds.length - 1) {
                        require(
                            msg.sender == owner,
                            "Only owner and buyer can get order details."
                        );
                    }
                }
            }
        }

        Order memory _order = orders[_orderId];
        return (
            _order.id,
            _order.productIds,
            _order.quantities,
            _order.price,
            _order.status,
            _order.dateTime
        );
    }

    // Function to get coupon details by coupon id
    function getCoupon(
        uint256 _couponId
    )
        public
        view
        returns (
            uint256 id,
            string memory name,
            uint256 discountPercentage,
            uint256 status
        )
    {
        require(
            _couponId > 0 && _couponId <= couponCount,
            "Invalid coupon id."
        );

        Coupon memory _coupon = coupons[_couponId];
        return (
            _coupon.id,
            _coupon.name,
            _coupon.discountPercentage,
            _coupon.status
        );
    }

    // Function to apply coupon by coupon name and return coupon id
    function applyCoupon(
        string memory _couponName
    ) public view returns (uint256) {
        require(
            bytes(_couponName).length > 0,
            "Coupon name should not be empty or null."
        );

        for (uint256 i = 1; i <= couponCount; i++) {
            if (
                keccak256(bytes(coupons[i].name)) ==
                keccak256(bytes(_couponName))
            ) {
                return coupons[i].id;
            }
        }
        return 0;
    }

    // ------------------- Updaters -------------------

    // Function to update product status by product id
    function updateProductStatus(
        uint256 _productId,
        uint256 _status
    ) public onlyOwner {
        require(
            _productId > 0 && _productId <= productCount,
            "Invalid product id."
        );
        require(
            _status == 0 || _status == 1,
            "Status should be either 0 or 1."
        );

        products[_productId].status = _status;
    }

    // Function to update coupon status by coupon id
    function updateCouponStatus(
        uint256 _couponId,
        uint256 _status
    ) public onlyOwner {
        require(
            _couponId > 0 && _couponId <= couponCount,
            "Invalid coupon id."
        );
        require(
            _status == 0 || _status == 1,
            "Status should be either 0 or 1."
        );

        coupons[_couponId].status = _status;
    }

    // Function to update product quantity by product id
    function updateProductQuantity(
        uint256 _productId,
        uint256 _quantity
    ) public onlyOwner {
        require(
            _productId > 0 && _productId <= productCount,
            "Invalid product id."
        );
        require(_quantity > 0, "Quantity should be greater than 0.");

        products[_productId].quantity = _quantity;
    }

    // Function to update product price by product id
    function updateProductPrice(
        uint256 _productId,
        uint256 _price
    ) public onlyOwner {
        require(
            _productId > 0 && _productId <= productCount,
            "Invalid product id."
        );
        require(_price > 0, "Price should be greater than 0.");

        products[_productId].price = _price;
    }

    // Function to update coupon discount percentage by coupon id
    function updateCouponDiscountPercentage(
        uint256 _couponId,
        uint256 _discountPercentage
    ) public onlyOwner {
        require(
            _couponId > 0 && _couponId <= couponCount,
            "Invalid coupon id."
        );
        require(
            _discountPercentage > 0,
            "Discount percentage should be greater than 0."
        );

        coupons[_couponId].discountPercentage = _discountPercentage;
    }

    // Function to update user address by user wallet address
    function updateUserAddress(
        address _walletAddress,
        string memory _address
    ) public {
        require(
            _walletAddress != address(0),
            "Wallet address should not be empty or null."
        );
        require(
            msg.sender == owner || msg.sender == _walletAddress,
            "Only owner and user can update user address."
        );
        require(
            bytes(_address).length > 0,
            "Address should not be empty or null."
        );

        for (uint256 i = 1; i <= userCount; i++) {
            if (users[i].walletAddress == payable(_walletAddress)) {
                users[i]._address = _address;
                break;
            }
        }
    }

    // Function to update user phone by user wallet address
    function updateUserPhone(
        address _walletAddress,
        string memory _phone
    ) public {
        require(
            _walletAddress != address(0),
            "Wallet address should not be empty or null."
        );
        require(
            msg.sender == owner || msg.sender == _walletAddress,
            "Only owner and user can update user phone."
        );
        require(bytes(_phone).length > 0, "Phone should not be empty or null.");

        for (uint256 i = 1; i <= userCount; i++) {
            if (users[i].walletAddress == payable(_walletAddress)) {
                users[i].phone = _phone;
                break;
            }
        }
    }

    // Function to update order status to 0 if delivered
    function orderDelivered(uint256 _orderId) public onlyOwner {
        require(_orderId > 0 && _orderId <= orderCount, "Invalid order id.");

        orders[_orderId].status = 0;
    }

    // Function to transfer ownership
    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(
            _newOwner != address(0),
            "New owner address should not be empty or null."
        );

        owner = _newOwner;
    }

    // Function to update carewell token
    function updateCarewellToken(address _carewellToken) public onlyOwner {
        require(
            _carewellToken != address(0),
            "Carewell token address should not be empty or null."
        );

        carewellToken = IERC20(_carewellToken);
    }

    // ------------------- Destructors -------------------

    // Function to destroy contract
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}
