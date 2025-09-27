// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SavingsAccount
 * @dev A decentralized savings account smart contract that allows users to deposit ETH,
 * earn interest over time, and withdraw their funds with accumulated interest.
 */
contract SavingsAccount {
    
    // Interest rate: 5% per year (represented as 5 for 5%)
    uint256 public constant ANNUAL_INTEREST_RATE = 5;
    uint256 public constant SECONDS_PER_YEAR = 365 * 24 * 60 * 60;
    
    // Account structure to store user's savings data
    struct Account {
        uint256 balance;
        uint256 depositTime;
        bool exists;
    }
    
    // Mapping from user address to their account
    mapping(address => Account) public accounts;
    
    // Contract owner
    address public owner;
    
    // Total contract balance for interest calculation
    uint256 public totalDeposits;
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 principal, uint256 interest, uint256 timestamp);
    event InterestCalculated(address indexed user, uint256 interest);
    
    // Modifiers
    modifier onlyAccountHolder() {
        require(accounts[msg.sender].exists, "Account does not exist");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Deposit ETH to savings account
     * Users can deposit ETH to start earning interest
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // If account exists, calculate and add interest to current balance before new deposit
        if (accounts[msg.sender].exists) {
            uint256 interest = calculateInterest(msg.sender);
            accounts[msg.sender].balance += interest;
            emit InterestCalculated(msg.sender, interest);
        } else {
            accounts[msg.sender].exists = true;
        }
        
        // Add new deposit to balance
        accounts[msg.sender].balance += msg.value;
        accounts[msg.sender].depositTime = block.timestamp;
        
        // Update total deposits
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Core Function 2: Calculate accumulated interest for a user
     * @param user The address of the account holder
     * @return interest The calculated interest amount
     */
    function calculateInterest(address user) public view returns (uint256 interest) {
        require(accounts[user].exists, "Account does not exist");
        
        Account memory account = accounts[user];
        if (account.balance == 0) {
            return 0;
        }
        
        // Calculate time elapsed since last deposit/interest calculation
        uint256 timeElapsed = block.timestamp - account.depositTime;
        
        // Calculate interest: (balance * rate * time) / (100 * seconds_per_year)
        interest = (account.balance * ANNUAL_INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
        
        return interest;
    }
    
    /**
     * @dev Core Function 3: Withdraw funds with accumulated interest
     * @param amount The amount to withdraw (0 means withdraw all)
     */
    function withdraw(uint256 amount) external onlyAccountHolder {
        // Calculate current interest
        uint256 interest = calculateInterest(msg.sender);
        uint256 totalBalance = accounts[msg.sender].balance + interest;
        
        // If amount is 0, withdraw everything
        if (amount == 0) {
            amount = totalBalance;
        }
        
        require(amount <= totalBalance, "Insufficient balance");
        require(address(this).balance >= amount, "Contract has insufficient funds");
        
        // Calculate how much is principal vs interest
        uint256 principalWithdrawn;
        uint256 interestWithdrawn;
        
        if (amount <= accounts[msg.sender].balance) {
            principalWithdrawn = amount;
            interestWithdrawn = 0;
            accounts[msg.sender].balance -= amount;
        } else {
            principalWithdrawn = accounts[msg.sender].balance;
            interestWithdrawn = amount - principalWithdrawn;
            accounts[msg.sender].balance = 0;
        }
        
        // Update total deposits
        totalDeposits -= principalWithdrawn;
        
        // Reset deposit time if there's remaining balance
        if (accounts[msg.sender].balance > 0) {
            accounts[msg.sender].depositTime = block.timestamp;
        } else {
            // Close account if balance is 0
            accounts[msg.sender].exists = false;
            accounts[msg.sender].depositTime = 0;
        }
        
        // Transfer funds to user
        payable(msg.sender).transfer(amount);
        
        emit Withdrawal(msg.sender, principalWithdrawn, interestWithdrawn, block.timestamp);
    }
    
    // Additional utility functions
    
    /**
     * @dev Get account details for a user
     * @param user The address to query
     * @return balance Current balance
     * @return depositTime Last deposit time
     * @return currentInterest Accumulated interest
     * @return totalValue Total balance + interest
     */
    function getAccountDetails(address user) external view returns (
        uint256 balance,
        uint256 depositTime,
        uint256 currentInterest,
        uint256 totalValue
    ) {
        require(accounts[user].exists, "Account does not exist");
        
        balance = accounts[user].balance;
        depositTime = accounts[user].depositTime;
        currentInterest = calculateInterest(user);
        totalValue = balance + currentInterest;
    }
    
    /**
     * @dev Check if an account exists
     * @param user The address to check
     * @return exists Whether the account exists
     */
    function accountExists(address user) external view returns (bool exists) {
        return accounts[user].exists;
    }
    
    /**
     * @dev Get contract statistics
     * @return contractBalance Current contract ETH balance
     * @return totalDeposited Total amount deposited by all users
     * @return interestRate Annual interest rate percentage
     */
    function getContractStats() external view returns (
        uint256 contractBalance,
        uint256 totalDeposited,
        uint256 interestRate
    ) {
        return (address(this).balance, totalDeposits, ANNUAL_INTEREST_RATE);
    }
    
    /**
     * @dev Emergency function to add funds to contract (only owner)
     */
    function addFunds() external payable onlyOwner {
        // Allows owner to add ETH to ensure contract can pay interest
    }
    
    /**
     * @dev Get contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
