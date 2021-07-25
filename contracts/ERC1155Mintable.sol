pragma solidity ^0.5.0;

import "./ERC1155.sol";

contract ERC1155Mintable is ERC1155 {

    struct Royalties {
        uint256 id;
        address issuer;
        uint256 royalties;
    }
    
    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    mapping (uint256 => address) public creators;
    mapping (uint256 => Royalties) public royalties;
    
    uint256 public nonce;

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

    
    function mint(uint256 _initialSupply, uint256 _royalties, string calldata _uri) external returns(uint256 _id) {

        require(_royalties >= 0 && _royalties <= 25);
        
        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;
        royalties[_id] = Royalties(_id, msg.sender, _royalties);
        
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);
            
    }

}