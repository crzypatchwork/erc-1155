pragma solidity ^0.5.0;

pragma experimental ABIEncoderV2;

import "./ERC1155.sol";

contract ERC1155Mintable is ERC1155 {

    struct Royalties {
        uint256 id;
        address issuer;
        uint256 royalties;
    }
    
    mapping (uint256 => address) public creators;
    mapping (uint256 => Royalties) public royalties;
    
    uint256 public nonce;

    function royaltiesView(uint256 _id) external view returns(Royalties memory) {
        return royalties[_id];
    }

    function mint(uint256 _initialSupply, uint256 _royalties, string calldata _uri) external returns(uint256 _id) {

        require(_royalties >= 0 && _royalties <= 250 && _initialSupply > 0 && _initialSupply <= 10000);
        
        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;
        royalties[_id] = Royalties(_id, msg.sender, _royalties);
        
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);
            
    }

}
