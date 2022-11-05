// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    uint public _p_id =0;
    uint public _u_id =0;
    uint public _t_id=0;
    
    struct track_product {
        uint _product_id;
        uint _owner_id;
        address _product_owner;
        uint _timeStamp;
    }

    mapping(uint => track_product) public tracks;
    
    struct product {
        string _product_name;
        uint _product_cost;
        string _product_specs;
        string _product_review;
        address _product_owner;
        uint _manufacture_date;
    }
    
    mapping(uint => product) public products;
    
    struct participant {
        string _userName;
        string _passWord;
        address _address;
        string _userType;
    }

    mapping(uint => participant) private participants;
    
    function createParticipant(string memory name ,string memory pass ,address u_add ,string memory utype) public returns (uint){
        uint user_id = _u_id++;
        participants[user_id]._userName = name ;
        participants[user_id]._passWord = pass;
        participants[user_id]._address = u_add;
        participants[user_id]._userType = utype;
        return user_id;
    }
    
    function newProduct(uint own_id, string memory name ,uint p_cost ,string memory p_specs ,string memory p_review) public returns (uint) {
        require(keccak256(bytes(participants[own_id]._userType)) == keccak256(bytes("Manufacturer")), "Only Manufacturer can add products");
            uint product_id = _p_id++;
            products[product_id]._product_name = name;
            products[product_id]._product_cost = p_cost;
            products[product_id]._product_specs =p_specs;
            products[product_id]._product_review =p_review;
            products[product_id]._product_owner = participants[own_id]._address;
            products[product_id]._manufacture_date = block.timestamp;
            return product_id;   
    }

    function getParticipant(uint p_id) public view returns (string memory,address,string memory) {
        return (participants[p_id]._userName,participants[p_id]._address,participants[p_id]._userType);
    }

    function getProduct_details(uint prod_id) public view returns (string memory,uint,string memory,string memory,address,uint) {
        return (products[prod_id]._product_name,products[prod_id]._product_cost,products[prod_id]._product_specs,products[prod_id]._product_review,products[prod_id]._product_owner,products[prod_id]._manufacture_date);
    }

    modifier onlyOwner(uint user1_id,uint pid) {
         require(participants[user1_id]._address == products[pid]._product_owner, 
         "Provided user is not the owner of the given product" );
         _;
    }
    
function transferOwnership_product(uint user1_id ,uint user2_id, uint prod_id) onlyOwner(user1_id,prod_id) public {
    
        participant memory p1 = participants[user1_id];
        participant memory p2 = participants[user2_id];
        uint track_id = _t_id++;
   
        require(keccak256(bytes(p1._userType)) == keccak256(bytes("Manufacturer")) && keccak256(bytes(p2._userType))==keccak256(bytes("Supplier")) || 
        keccak256(bytes(p1._userType)) == keccak256(bytes("Supplier")) && keccak256(bytes(p2._userType))==keccak256(bytes("Supplier")) ||
        keccak256(bytes(p1._userType)) == keccak256(bytes("Supplier")) && keccak256(bytes(p2._userType))==keccak256(bytes("Customer")), 
        "Transfer of ownership can only happen from Manufacturer to Supplier to Consumer");
            tracks[track_id]._product_id =prod_id;
            tracks[track_id]._product_owner = p2._address;
            tracks[track_id]._owner_id = user2_id;
            tracks[track_id]._timeStamp = block.timestamp;
            products[prod_id]._product_owner = p2._address;
            
    }
  
    function getProduct_trackindex(uint trck_id)  public view returns (uint,uint,address,uint) {
        track_product memory t = tracks[trck_id];
        return (t._product_id,t._owner_id,t._product_owner,t._timeStamp);
    }
    
}