// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    uint public _p_id =0;   // Product ID
    uint public _u_id =0;   // User ID    
    uint public _o_id=0;    // Order ID

    struct order {
        uint _order_id;
        uint _product_id;
        uint _quantity;
        uint _customer_id;
        uint _manufacturer_id;
        uint _amount;
    }
    
    // mapping from _o_id to order
    mapping (uint => order) private orders;       

    struct owner {
        uint _owner_id;
        address _product_owner;
        uint _timeStamp;
    }

    enum order_status{Pending,Confirmed,Cancelled,Shipped,Delivered}

    struct track_order {
        uint _order_id;
        uint _product_id;
        uint _current_owner_id;
        order_status status;
        owner[] owners;
    }

    // mapping from _o_id to track_order
    mapping(uint => track_order) private tracks;      
    
    struct product {
        string _product_name;
        uint _product_cost;
        string _product_specs;
        string _product_review;
        uint _manufacturer_id;
        uint _manufacture_date;
    }
    
    // mapping from _p_id to product
    mapping(uint => product) public products;
    
    struct participant {
        string _userName;
        address _address;
        string _userType;
    }

    // mapping from _u_id to participant
    mapping(uint => participant) public participants;
    
    function createParticipant(string memory name ,string memory utype) public returns (uint){
        uint user_id = _u_id++;
        participants[user_id]._userName = name ;
        participants[user_id]._address = msg.sender;
        participants[user_id]._userType = utype;
        return user_id;
    }
    
    function newProduct(uint user_id, string memory name ,uint p_cost ,string memory p_specs ,string memory p_review) public returns (uint) {
        require(keccak256(bytes(participants[user_id]._userType)) == keccak256(bytes("Manufacturer")), "Only Manufacturer can add products");
        require(msg.sender == participants[user_id]._address, "Your User ID (Owner ID) does not match");
        uint product_id = _p_id++;
        products[product_id]._product_name = name;
        products[product_id]._product_cost = p_cost;
        products[product_id]._product_specs =p_specs;
        products[product_id]._product_review =p_review;
        products[product_id]._manufacturer_id = user_id;
        products[product_id]._manufacture_date = block.timestamp;
        return product_id;   
    }

    function placeOrder(uint customer_id, uint prod_id, uint qty) public returns (uint) {
        require(keccak256(bytes(participants[customer_id]._userType)) == keccak256(bytes("Customer")), "Only customer can place order");
        require(msg.sender == participants[customer_id]._address, "Your User ID (Customer ID) does not match");
        uint order_id = _o_id++;
        orders[order_id]._order_id = order_id;
        orders[order_id]._product_id = prod_id;
        orders[order_id]._quantity = qty;
        orders[order_id]._customer_id = customer_id;
        orders[order_id]._manufacturer_id = products[prod_id]._manufacturer_id;
        orders[order_id]._amount = orders[order_id]._quantity * products[prod_id]._product_cost;
        tracks[order_id].status = order_status.Pending;
        tracks[order_id]._current_owner_id = orders[order_id]._manufacturer_id;
        owner memory new_owner;
        new_owner._owner_id = orders[order_id]._manufacturer_id;
        new_owner._product_owner = participants[orders[order_id]._manufacturer_id]._address;
        new_owner._timeStamp = block.timestamp;
        tracks[order_id].owners.push(new_owner);
        return order_id;
    }

    function confirmOrder(uint manufacturer_id, uint order_id) public {
        require(tracks[order_id].status == order_status.Pending, "Only pending order can be confirmed");
        require(msg.sender == participants[manufacturer_id]._address, "Your User ID (Manufacturer ID) does not match");
        require(manufacturer_id == orders[order_id]._manufacturer_id, "You are not the manufacturer of the product ordered");
        tracks[order_id].status = order_status.Confirmed;
    }

    function cancelOrder(uint customer_id, uint order_id) public {
        require(keccak256(bytes(participants[customer_id]._userType)) == keccak256(bytes("Customer")), "Only customer can cancel order");
        require(tracks[order_id].status == order_status.Pending || tracks[order_id].status == order_status.Confirmed, "Only pending or confirmed order can be cancelled");
        require(msg.sender == participants[customer_id]._address, "Your User ID (Customer ID) does not match");
        require(customer_id == orders[order_id]._customer_id, "You have not ordered this product");
        tracks[order_id].status = order_status.Cancelled;
    }

    modifier onlyOwner(uint user1_id,uint order_id) {
        require(tracks[order_id]._current_owner_id == user1_id, "Provided user is not the current owner of the given order");
        _;
    }
    
    function transferOwnership_product(uint user1_id ,uint user2_id, uint order_id) onlyOwner(user1_id,order_id) public {
    
        participant memory p1 = participants[user1_id];
        participant memory p2 = participants[user2_id];
   
        require(keccak256(bytes(p1._userType)) == keccak256(bytes("Manufacturer")) && keccak256(bytes(p2._userType))==keccak256(bytes("Supplier")) || 
        keccak256(bytes(p1._userType)) == keccak256(bytes("Supplier")) && keccak256(bytes(p2._userType))==keccak256(bytes("Supplier")) ||
        keccak256(bytes(p1._userType)) == keccak256(bytes("Supplier")) && keccak256(bytes(p2._userType))==keccak256(bytes("Customer")), 
        "Transfer of ownership can only happen from Manufacturer to Supplier to Consumer");
        require(tracks[order_id].status != order_status.Cancelled, "Provided order is cancelled by the customer");
        tracks[order_id]._current_owner_id = user2_id;
        owner memory new_owner;
        new_owner._owner_id = user2_id;
        new_owner._product_owner = participants[user2_id]._address;
        new_owner._timeStamp = block.timestamp;   
        tracks[order_id].status = order_status.Shipped;  
        tracks[order_id].owners.push(new_owner);  
    }

    function getOrderDetails(uint order_id) public view returns (uint product_id, string memory product_name, uint quantity, uint amount) {
        return(orders[order_id]._product_id, products[orders[order_id]._product_id]._product_name, orders[order_id]._quantity, orders[order_id]._amount);
    }
  
    
    function trackYourOrder(uint order_id)  public view returns (uint product_id, uint current_owner_id, order_status status, owner [] memory owners) {
        return (tracks[order_id]._product_id, tracks[order_id]._current_owner_id, tracks[order_id].status, tracks[order_id].owners);
    }
    

    function acceptOrderAndPay(uint order_id, uint customer_id) external payable{
        require(keccak256(bytes(participants[customer_id]._userType)) == keccak256(bytes("Customer")), "Only customer can receive order");
        require(msg.sender == participants[customer_id]._address, "Your User ID (Customer ID) does not match");
        require(customer_id == orders[order_id]._customer_id, "You have not ordered this product");
        require(msg.value == orders[order_id]._amount, "Payment amount not equal to order total");
        require(tracks[order_id]._current_owner_id == customer_id, "Order not yet delivered to you");   
        tracks[order_id].status = order_status.Delivered;
        address payable recipient = payable(participants[orders[order_id]._manufacturer_id]._address);
        recipient.transfer(msg.value);
    }
    
}