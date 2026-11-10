
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

// Parent Contract
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid owner address");

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
}

// Child Contract
contract ProtectedVault is Ownable {
    uint256 private treasure;

    event Deposited(address indexed sender, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    // Anyone can deposit ETH
    function deposit() public payable {
        treasure += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Only owner can withdraw ETH
    function withdraw(address to, uint256 amt) public onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(amt <= address(this).balance, "Insufficient balance");

        require(amt <= treasure, "Insufficient treasure");

        treasure -= amt;

        (bool success, ) = payable(to).call{value: amt}("");
        require(success, "ETH transfer failed");

        emit Withdrawn(to, amt);
    }

    // Return the actual ETH balance of the contract
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
