// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract Storage {
    uint256 private storedData;

    event ValueSet(address indexed who, uint256 newValue);

    constructor(uint256 _init) {
        storedData = _init;
        emit ValueSet(msg.sender, _init);
    }

    function set(uint256 _value) public {
        storedData = _value;
        emit ValueSet(msg.sender, _value);
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}
