/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface AuthenticationInterface {
    function getUser(address _address) external view returns (string memory fullname, string memory id, string memory phone);
    function isBuyer(address _address) external view returns (bool);
    function isSeller(address _address) external view returns (bool);
    function isCourier(address _address) external view returns (bool);
}

contract MarketPlace {
    AuthenticationInterface auth;

    //Entities' counters
    uint sellerCounter = 0;
    uint productCounter = 0;
    uint orderDetailCounter = 0;
    uint orderCounter = 0;
    uint deliveryDetailCounter = 0;

    //Courier fixed cost
    uint courierCost = 2 * (10 ** 14);

    //Order states
    enum State { AWAITING, IN_PROCESS, DELIVERED, COMPLETED }

    //Structs
    struct Seller {
        uint id;
        string location;
        string street_address;
        address account;
    }

    struct Product {
        uint id;
        string title;
        string description;
        string image;
        uint price;
        uint sellerId;
        address seller;
    }

    struct Order {
        uint id;
        uint orderType;
        uint initialTime;
        uint finalTime;
        uint orderCost;
        uint courierCost;
        uint totalCost;
        address buyer;
        address courier;
        Seller seller;
        uint rank;
        State currentState;
    }

    struct OrderDetail {
        uint id;
        uint orderId;
        uint quantity;
        Product product;
    }

    struct DeliveryDetail {
        string destinationAddress;
        string userId;
        string userFullName;
        string phone;
        string comment;
    }

    //Mappings
    mapping (uint => Seller) private sellers;
    mapping (uint => Product) private products;
    mapping (uint => OrderDetail[]) private orderDetails;
    mapping (uint => Order) private orders;
    mapping (uint => DeliveryDetail) private deliveryDetails;

    function setAuthenticationContractAddress(address _address) external {
        auth = AuthenticationInterface(_address);
    }

    //Seller
    function addSeller(string memory _location, string memory _street_address) public {
        require(auth.isSeller(msg.sender), "You must be a Seller.");

        sellers[sellerCounter] = Seller(sellerCounter, _location, _street_address, msg.sender);
        sellerCounter++;
    }

    function getSeller(uint _sellerId) public view returns (Seller memory) {
        return sellers[_sellerId];
    }

    function getSellers() public view returns (Seller[] memory){
        Seller[] memory arrSeller = new Seller[](sellerCounter);
        for (uint i = 0; i < sellerCounter; i++) {
            Seller storage seller = sellers[i];
            arrSeller[i] = seller;
        }
        return arrSeller;
    }

    //Product
    function addProduct(string memory _title, string memory _description, string memory _image, uint _price, uint _sellerId) public {
        require(auth.isSeller(msg.sender), "You must be a Seller.");
        require(_price > 0, "Price should be greather than zero");

        products[productCounter] = Product(productCounter, _title, _description, _image, (_price * (10**14)), _sellerId, msg.sender);
        productCounter++;
	}

    function getProduct(uint _productId) public view returns (Product memory) {
        return products[_productId];
    }

    function getProducts() public view returns (Product[] memory){
        Product[] memory arrProduct = new Product[](productCounter);
        for (uint i = 0; i < productCounter; i++) {
            Product storage product = products[i];
            arrProduct[i] = product;
        }
        return arrProduct;
    }

    //OrderDetail
    function addOrderDetail(uint _quantity, uint _idProduct) public {
        require(auth.isBuyer(msg.sender), "You must be a Buyer.");

        Product storage product = products[_idProduct];
        orderDetails[orderCounter].push(OrderDetail(orderDetailCounter, orderCounter, _quantity, product));
        orderDetailCounter++;
    }   

    function getOrderDetails() public view returns (OrderDetail[] memory) {
        return orderDetails[orderCounter];
    }

    function getOrderDetailsByOrderId(uint _orderId) public view returns (OrderDetail[] memory) {
        return orderDetails[_orderId];
    }

    function deleteOrderDetail(uint _index) public {
        require(auth.isBuyer(msg.sender), "You must be a Buyer.");

        delete orderDetails[orderCounter][_index];
    }

    //Order
    function addOrder(uint _sellerId, uint _orderType, string memory _destinationAddress) public payable {
        require(auth.isBuyer(msg.sender), "You must be a Buyer.");

        uint orderCost = calculateOrderCost();
        require(msg.value == (orderCost + courierCost), "You must deposit the full money");

        uint totalCost = orderCost + courierCost;
        Seller storage seller = sellers[_sellerId];
        orders[orderCounter] = Order(orderCounter, _orderType, block.timestamp, block.timestamp, orderCost, courierCost, totalCost, msg.sender, address(0), seller, 0, State.AWAITING);

        string memory _fullname;
        string memory _id;
        string memory _phone;
        (_fullname, _id, _phone) = auth.getUser(msg.sender);
        deliveryDetails[orderCounter] = DeliveryDetail(_destinationAddress, _id, _fullname, _phone, "");

        orderCounter++;
    }

    function getOrders() public view returns (Order[] memory){
        Order[] memory arrOrder = new Order[](orderCounter);
        for (uint i = 0; i < orderCounter; i++) {
            Order storage order = orders[i];
            arrOrder[i] = order;
        }
        return arrOrder;
    }

    function getOrder(uint _orderId) public view returns (Order memory) {
        return orders[_orderId];
    }

    function attendOrder(uint _orderId) public {
        require(auth.isCourier(msg.sender), "You must be a Courier.");

        orders[_orderId].courier = msg.sender;
        orders[_orderId].currentState = State.IN_PROCESS;
    }

    function deliverOrder(uint _orderId, string memory _comment) public {
        require(auth.isCourier(msg.sender), "You must be a Courier.");

        orders[_orderId].currentState = State.DELIVERED;
        deliveryDetails[_orderId].comment = _comment;
    }

    function getDeliveryDetails(uint _orderId) public view returns (DeliveryDetail memory) {
        return deliveryDetails[_orderId];
    }

    function completeOrder(uint _orderId) public {
        require(auth.isBuyer(msg.sender), "You must be a Buyer.");

        Order storage order = orders[_orderId];
        payable(order.courier).transfer(order.courierCost);
        payable(order.seller.account).transfer(order.orderCost);
        order.finalTime = block.timestamp;
        order.currentState = State.COMPLETED;
    }

    function qualifyOrder(uint _orderId, uint _rank) public {
        require(auth.isBuyer(msg.sender), "You must be a Buyer.");

        orders[_orderId].rank = _rank;
    }

    //Utils
    function calculateOrderCost() private view returns (uint) {
        uint total = 0;
        OrderDetail[] memory arrOrderDetail = getOrderDetails();
        for(uint i = 0; i < arrOrderDetail.length; i++) {
            total += arrOrderDetail[i].quantity * arrOrderDetail[i].product.price;
        }
        return total;
    }
}