
pragma solidity >=0.7.0 <0.9.0;

// @hicetnunc2000 @crzypatchwork
// github.com/hicetnunc2000

//           __     /_/ __    ______           
//    ____  / /__  __  / /__ /_  __/  
//   /   / /    / / / /   _/  / /     
//  /___/ /____/ / / /_/\_\  /_/    
//             _/ /
//            /__/                  v0.1 solidity



interface ERC1155Interface {
    
    function safeTransferFrom(        
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external;
            
}

struct SwapStruct {
    
    address issuer; // msg.sender swap issuer
    address creator; // erc1155 token creator
    uint amount;
    uint value;
    uint id;
    uint royalties;
    
}

contract OBJKTSwap {
    
    address public erc1155;
    address public manager;
    uint public fee;
    uint public nonce;
    
    mapping(uint => SwapStruct) public swaps;
    
    constructor(address _manager, address _erc1155, uint _fee) public {
        manager = _manager;
        erc1155 = _erc1155;
        fee = _fee;
    }
    
    // management
    
    function updateFee(uint _fee) public {
        require(msg.sender == manager);
        fee = _fee;
    }
    
    function updateManager(address _manager) public {
        require(msg.sender == manager);
        manager = _manager;
    }
    
    function transfer(address _from, address _to, uint256 _id, uint256 _amount) public {
        require(msg.sender == address(this));
        ERC1155Interface(erc1155).safeTransferFrom(_from, _to, _id, _amount, '0x00');
    }
    
    // erc1155 approval must be given
    
    function swap(uint _id, uint _amount, uint _value, uint _royalties, address _creator) public {
        
        require((_value >= 1000) && (_royalties >= 0) && (_royalties <= 250));
        nonce++;
        SwapStruct storage e = swaps[nonce];
        e.issuer = msg.sender;
        e.creator = _creator;
        e.amount = _amount;
        e.value = _value;
        e.id = _id;
        e.royalties = _royalties;
        this.transfer(msg.sender, address(this), _id, _amount);
        
    }
    
    function collect(uint swap_id) public payable {
        
        require((msg.value == swaps[swap_id].value) && (swaps[swap_id].amount > 0) && ((msg.value == 0) || (msg.value >= 1000)));

        // msg.value 18 decimals (wei)
        
        uint auxDistribution = ((swaps[swap_id].royalties + fee) * msg.value) / 1000;
        uint auxFee = ((fee * msg.value) / 1000);
        
        // distribute fees
        
        manager.call{ value : auxFee }("");
        
        // distribute royalties
        
        swaps[swap_id].creator.call{ value : auxDistribution - auxFee }("");
        
        // final distribution
        
        swaps[swap_id].issuer.call{ value : msg.value - auxDistribution }("");
        
        // transfer token
        
        this.transfer(address(this), msg.sender, swaps[swap_id].id, 1);
        swaps[swap_id].amount--;
        
    }
    
}