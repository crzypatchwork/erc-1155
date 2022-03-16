pragma solidity >=0.7.0 <0.9.0;

contract Bytes {
    bytes32 public test;
    
    function call(bytes32 _test) public {
        test = _test;
    }
}

struct Metadata {
    bytes32 metadata;
    address issuer;
    bool isValue;
}

contract Subjkt {
    
    event subjktLog(bytes32 _metadata, bytes32 indexed _subjkt);
    
    mapping(bytes32 => Metadata) public subjktsMetadata;
    mapping(address => bytes32) public registries;
    mapping(address => bool) public entries;
    mapping(bytes32 => bool) public subjkts;

    
    function removeAddress(address _address) internal {
        if (entries[_address]) delete entries[_address];
        if (subjkts[registries[_address]]) delete subjkts[registries[_address]];
        delete subjktsMetadata[registries[_address]];
        delete registries[_address];
    }
    
    function register(bytes32 _subjkt, bytes32 _metadata) public {
        if (subjkts[_subjkt]) require(registries[msg.sender] == _subjkt);
        removeAddress(msg.sender);
        if (subjktsMetadata[_subjkt].isValue) require(subjktsMetadata[_subjkt].issuer == msg.sender);
        
        entries[msg.sender] = true;
        subjkts[_subjkt] = true;
        
        subjktsMetadata[_subjkt] = Metadata(_metadata, msg.sender, true);
        registries[msg.sender] = _subjkt;
        
        emit subjktLog(_metadata, _subjkt);
        
    }
    
}