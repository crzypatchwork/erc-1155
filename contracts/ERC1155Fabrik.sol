pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

/**
 * @title SafeMathƒ
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * Utility library of inline functions on addresses
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

contract CommonConstants {

    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

interface ERC1155TokenReceiver {

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}


interface IERC1155  {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _tokenId);

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// https://docs.opensea.io/docs/metadata-standards#freezing-metadata

contract Multable {
    event PermanentURI(string _value, uint256 indexed _id);
}

struct Royalties {
    address issuer;
    uint256 royalties;
}

contract ERC1155 is IERC1155, ERC165, CommonConstants, Multable
{
    using SafeMath for uint256;
    using Address for address;

    mapping (uint256 => mapping(address => uint256)) internal balances;
    mapping (address => mapping(address => bool)) internal operatorApproval;

/////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256('supportsInterface(bytes4)'));
    */
    
    //bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */

/////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external override {

        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);
        IStar(star).transferSingle(msg.sender, _from, _to, _id, _value);

    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override{

        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array length must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to]   = value.add(balances[id][_to]);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
        IStar(star).transferBatch(msg.sender, _from, _to, _ids, _values);
    }

    function balanceOf(address _owner, uint256 _id) external override view returns (uint256) {
        return balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external override view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

/////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {
        require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {
        require(ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == ERC1155_BATCH_ACCEPTED, "contract returned an unknown value from onERC1155BatchReceived");
    }

    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    
    mapping (uint256 => address) public creators;
    mapping (uint256 => uint256) public royalties;
    mapping (uint256 => string) public uri;
    mapping (uint256 => bool) public frozen;
    mapping (address => bool) public auths;

    uint public nonce;
    string public name;
    string public symbol;
    string private collectionUri;
    address public star;

    constructor (string memory _name, string memory _symbol, string memory _collectionUri, address _address) public {
        name = _name;
        symbol = _symbol;
        collectionUri = _collectionUri;
        auths[_address] = true;
        star = msg.sender;
    }

    function auth() internal { require(auths[msg.sender]); }
    function addAuth(address _address) public { require(auths[msg.sender]); auths[_address] = true; }
    function removeAuth(address _address) public { require(auths[msg.sender]); delete auths[_address]; }


    function mint(uint256 _initialSupply, uint256 _royalties, string memory _tokenUri) public returns(uint256 _id) {
        auth();
        require(_royalties >= 0 && _royalties <= 2500 && _initialSupply > 0 && _initialSupply <= 20000 && bytes(_tokenUri).length > 0);
        
        // add  ███ fee?
        
        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;
        royalties[_id] = _royalties;
        
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);
        IStar(star).transferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);
        uri[_id] = _tokenUri;
        emit URI(_tokenUri, _id);
        IStar(star).uri(_tokenUri, _id);
        return _id;
    }
    
    function supportsInterface(bytes4 interfaceId) public override view returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC1155 || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_SIGNATURE_ERC165;
    }
    
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        return (creators[_tokenId], _salePrice*royalties[_tokenId]/10000);
    }

    // https://docs.opensea.io/docs/contract-level-metadata

    function contractURI() public view returns (string memory) { return collectionUri; }

    function updateContractURI(string memory _collectionUri) public { auth(); collectionUri = _collectionUri; }

    function updateName(string memory _name) public { auth(); name = _name; }

    // Multable

    function editURI(string memory _tokenUri, uint256 _id) public {
        require(msg.sender == creators[_id] && !frozen[_id]);
        uri[_id] = _tokenUri;
        emit URI(_tokenUri, _id);
    }

    function freezeURI(uint256 _id) public {
        require(msg.sender == creators[_id] && !frozen[_id]);
        frozen[_id] = true;
        emit PermanentURI(uri[_id], _id);
    }

}

interface IStar {
    function transferBatch(address, address, address, uint256[] calldata, uint256[] calldata) external;
    function transferSingle(address, address, address, uint256, uint256) external;
    function uri(string calldata, uint256) external;
    function auth(address, bool) external;
}

contract Star {

    event indexSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value, address _peer);
    event indexBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values, address _peer);
    event indexUri(string _uri, uint256 _id, address _peer);
    event peerLog(address _peer, address _address, bool _auth);

    mapping(address => bool) public peers;

    function createPeer(string calldata _name, string calldata _symbol, string calldata _collectionURI) public {
        address _peer = address(new ERC1155(_name, _symbol, _collectionURI, msg.sender));
        peers[_peer] = true;
        emit peerLog(_peer, msg.sender, true);
    }

    function transferSingle(address _operator, address _from, address _to, uint256 _id, uint256 _value) public {
        require(peers[msg.sender]);
        emit indexSingle(_operator, _from, _to, _id, _value, msg.sender);
    }

    function transferBatch(address _operator, address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) public {
        require(peers[msg.sender]);
        emit indexBatch(_operator, _from, _to, _ids, _values, msg.sender);
    }

    function uri(string calldata _uri, uint256 _id) public {
        require(peers[msg.sender]);
        emit indexUri(_uri, _id, msg.sender);
    }

    function auth(address _address, bool _auth) public {
        require(peers[msg.sender]);
        emit peerLog(msg.sender, _address, _auth);
    }
}