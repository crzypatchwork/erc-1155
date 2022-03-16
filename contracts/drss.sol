pragma solidity ^0.8.0;

contract dRSS {
    event sub(address, bool);
    function subscribe(address _address) public { emit sub(_address, true); }
    function unsubscribe(address _address) public { emit sub(_address, false); }
}