// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DAOTreasury {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public totalBalance;

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Deposit funds into the treasury
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Withdraw funds from the treasury
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= totalBalance, "Insufficient funds");
        payable(owner).transfer(amount);
        totalBalance -= amount;
        emit FundsWithdrawn(owner, amount);
    }

    // Check the balance of an address in the treasury
    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }
}
