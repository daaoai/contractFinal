// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DaosWorldV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;

    uint256 public constant SUPPLY_TO_LP = 100_000_000 ether;
    address public constant LEAF_POOL_FACTORY = 0x04625B046C69577EfC40e6c0Bb83CDBAfab5a55F;
    address public constant LEAF_ROUTER = 0x63951637d667f23D5251DEdc0f9123D22d8595be;
    address public constant WETH = 0xcc9ffcfBDFE629e9C62776fF01a75235F466794E;

    address public liquidityLocker;

    uint256 public totalRaised;
    uint256 public fundraisingGoal;
    bool public fundraisingFinalized;
    bool public goalReached;
    uint256 public fundraisingDeadline;
    uint256 public fundExpiry;
    uint256 public constant SUPPLY_TO_FUNDRAISERS = 1_000_000_000 * 1e18;
    uint8 public lpFeesCut = 60;
    address public protocolAdmin;
    string public name;
    string public symbol;
    address public daoToken;

    // Contribution mappings
    mapping(address => uint256) public contributions;
    address[] public contributors;

    event Contribution(address indexed contributor, uint256 amount);
    event FundraisingFinalized(bool success);
    event MintDetails(address indexed contributor, uint256 tokensToMint);
    event PoolCreated(address indexed pool);
    event TokenApproved(address indexed token, uint256 amount);
    event LPTokenMinted(address indexed pool);

    constructor(
        uint256 _fundraisingGoal,
        string memory _name,
        string memory _symbol,
        uint256 _fundraisingDeadline,
        uint256 _fundExpiry,
        address _protocolAdmin
    ) Ownable(msg.sender) {
        require(_fundraisingGoal > 0, "Fundraising goal must be greater than 0");
        require(_fundraisingDeadline > block.timestamp, "Deadline must be in the future");
        require(_fundExpiry > _fundraisingDeadline, "Expiry must be after the deadline");

        fundraisingGoal = _fundraisingGoal;
        fundraisingDeadline = _fundraisingDeadline;
        fundExpiry = _fundExpiry;
        protocolAdmin = _protocolAdmin;
        name = _name;
        symbol = _symbol;
    }

    function contribute() public payable nonReentrant {
        require(!goalReached, "Goal already reached");
        require(block.timestamp < fundraisingDeadline, "Deadline hit");
        require(msg.value > 0, "Contribution must be greater than 0");

        uint256 effectiveContribution = msg.value;
        if (totalRaised + msg.value > fundraisingGoal) {
            effectiveContribution = fundraisingGoal - totalRaised;
            payable(msg.sender).transfer(msg.value - effectiveContribution);
        }

        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }

        contributions[msg.sender] += effectiveContribution;
        totalRaised += effectiveContribution;

        emit Contribution(msg.sender, effectiveContribution);

        if (totalRaised == fundraisingGoal) {
            goalReached = true;
        }
    }

    function finalizeFundraising() external {
        require(goalReached, "Fundraising goal not reached");
        require(!fundraisingFinalized, "Already finalized");
        require(daoToken != address(0), "DAO token not set");

        ERC20 token = ERC20(daoToken);

        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contribution = contributions[contributor];
            uint256 tokensToMint = (contribution * SUPPLY_TO_FUNDRAISERS) / totalRaised;

            emit MintDetails(contributor, tokensToMint);

            token.transfer(contributor, tokensToMint);
        }

        fundraisingFinalized = true;

        address pool = createLeafPool();
        emit PoolCreated(pool);

        token.approve(LEAF_ROUTER, SUPPLY_TO_LP);
        emit TokenApproved(address(token), SUPPLY_TO_LP);

        // Deposit tokens into the pool via Leaf's router
        // Assume Leaf's router provides an addLiquidity function
        // This is a placeholder and should be replaced with the actual function call
        // emit LPTokenMinted(pool);
    }

    function createLeafPool() internal returns (address) {
        // Assume Leaf's pool factory has a `createPool` method
        // This is a placeholder and should be replaced with the actual function call
        address pool = address(0); // Replace with actual pool creation logic
        return pool;
    }

    function setDaoToken(address _daoToken) external onlyOwner {
        require(_daoToken != address(0), "Invalid DAO token address");
        require(daoToken == address(0), "DAO token already set");
        daoToken = _daoToken;
    }

    function refund() external nonReentrant {
        require(!goalReached, "Fundraising goal was reached");
        require(block.timestamp > fundraisingDeadline, "Deadline not reached yet");
        require(contributions[msg.sender] > 0, "No contributions to refund");

        uint256 contributedAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;

        payable(msg.sender).transfer(contributedAmount);
    }

    function emergencyEscape() external {
        require(msg.sender == protocolAdmin, "Must be protocol admin");
        require(!fundraisingFinalized, "Fundraising already finalized");

        (bool success,) = protocolAdmin.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    receive() external payable {
        if (!goalReached && block.timestamp < fundraisingDeadline) {
            contribute();
        }
    }
}
