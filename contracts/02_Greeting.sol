// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

contract Greeting {
    string private greeting;
    address public owner;

    string private constant DEFAULT_GREETING = "Hello, World!";

    event GreetingChanged(address changer, string newGreeting);

    constructor(string memory _g) {
        owner = msg.sender;
        greeting = _g;
        emit GreetingChanged(msg.sender, _g);
    }

    function setGreeting(string memory _g) public {
        require(msg.sender == owner, "Greeting: caller is not the owner");
        greeting = _g;
        emit GreetingChanged(msg.sender, _g);
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function resetGreeting() public {
        require(msg.sender == owner, "Greeting: caller is not the owner");
        greeting = DEFAULT_GREETING;
        emit GreetingChanged(msg.sender, DEFAULT_GREETING);
    }
}
