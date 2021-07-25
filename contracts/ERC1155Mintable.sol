pragma solidity ^0.5.0;

import "./ERC1155.sol";

contract ERC1155Mintable is ERC1155 {

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    mapping (uint256 => address) public creators;

    uint256 public nonce;
    
    address manager;
    
    constructor(address _manager) public {
        manager = _manager;
    }

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

    function supportsInterface(bytes4 _interfaceId)
    public
    view
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    function updateManager(address _manager) public {
        require(msg.sender == manager);
        manager = _manager;
    }
    
    // Creates a new token type and assings _initialSupply to minter
    function mint(address _target, uint256 _initialSupply, string calldata _uri) external returns(uint256 _id) {

        require(msg.sender == manager);
        
        _id = ++nonce;
        creators[_id] = _target;
        balances[_id][_target] = _initialSupply;

        // Transfer event with mint semantic
        emit TransferSingle(_target, address(0x0), _target, _id, _initialSupply);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);
    }

}