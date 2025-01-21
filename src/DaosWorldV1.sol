// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {INonfungiblePositionManager,IVelodromeFactory, IUniswapV3Factory, ILockerFactory, ILocker} from "./interface.sol";
import {IERC721Receiver} from "./LPLocker/IERC721Receiver.sol";
import {DaosWorldV1Token} from "./DaosWorldV1Token.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract DaosWorldV1 is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using TickMath for int24;

    uint24 public constant UNI_V3_FEE = 500;
    int24 public constant Ticker_Velo = 100;
    uint256 public constant SUPPLY_TO_LP = 0.0003 ether;
    IVelodromeFactory public constant Velodrome_factory = IVelodromeFactory(0x04625B046C69577EfC40e6c0Bb83CDBAfab5a55F);
    INonfungiblePositionManager public constant POSITION_MANAGER =
        INonfungiblePositionManager(0x991d5546C4B442B4c5fdc4c8B8b8d131DEB24702);
    address public constant WETH = 0x4200000000000000000000000000000000000006; 
    ILockerFactory public liquidityLockerFactory; 
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

    // If maxWhitelistAmount > 0, then its whitelist only. And this is the max amount you can contribute.
    uint256 public maxWhitelistAmount;
    // If maxPublicContributionAmount > 0, then you cannot contribute more than this in public rounds.
    uint256 public maxPublicContributionAmount;

    // The amount of ETH you've contributed
    mapping(address => uint256) public contributions;
    mapping(address => bool) public whitelist;
    address[] public whitelistArray;
    address[] public contributors;

    event Contribution(address indexed contributor, uint256 amount);
    event FundraisingFinalized(bool success);
    event Refund(address indexed contributor, uint256 amount);
    event AddWhitelist(address);
    event RemoveWhitelist(address);
    event DebugLog(string message);
    event MintDetails(address indexed contributor, uint256 tokensToMint);
    event PoolCreated(address indexed pool);
    event PoolInitialized(uint160 sqrtPriceX96);
    event MintParamsCreated(uint256 tokenId, address token0, address token1, uint256 liquidity);
    event TokenApproved(address indexed token, uint256 amount);
    event LPTokenMinted(uint256 tokenId);
    event LockerDeployed(address indexed lockerAddress);
    event TokenTransferredToLocker(uint256 tokenId, address lockerAddress);
    event LockerInitialized(uint256 tokenId);

    constructor(
        uint256 _fundraisingGoal,
        string memory _name,
        string memory _symbol,
        uint256 _fundraisingDeadline,
        uint256 _fundExpiry,
        address _daoManager,
        address _liquidityLockerFactory,
        uint256 _maxWhitelistAmount,
        address _protocolAdmin,
        uint256 _maxPublicContributionAmount
    ) Ownable(_daoManager) {
        require(_fundraisingGoal > 0, "Fundraising goal must be greater than 0");
        require(_fundraisingDeadline > block.timestamp, "_fundraisingDeadline > block.timestamp");
        require(_fundExpiry > fundraisingDeadline, "_fundExpiry > fundraisingDeadline");
        name = _name;
        symbol = _symbol;
        fundraisingGoal = _fundraisingGoal;
        fundraisingDeadline = _fundraisingDeadline;
        fundExpiry = _fundExpiry;
        liquidityLockerFactory = ILockerFactory(_liquidityLockerFactory);
        maxWhitelistAmount = _maxWhitelistAmount;
        protocolAdmin = _protocolAdmin;
        maxPublicContributionAmount = _maxPublicContributionAmount;
    }

    function contribute() public payable nonReentrant {
        require(!goalReached, "Goal already reached");
        require(block.timestamp < fundraisingDeadline, "Deadline hit");
        require(msg.value > 0, "Contribution must be greater than 0");
        if (maxWhitelistAmount > 0) {
            require(whitelist[msg.sender], "You are not whitelisted");
            require(contributions[msg.sender] + msg.value <= maxWhitelistAmount, "Exceeding maxWhitelistAmount");
        } else if (maxPublicContributionAmount > 0) {
            require(
                contributions[msg.sender] + msg.value <= maxPublicContributionAmount,
                "Exceeding maxPublicContributionAmount"
            );
        }

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

    function addToWhitelist(address[] calldata addresses) external {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        for (uint256 i = 0; i < addresses.length; i++) {
            if (!whitelist[addresses[i]]) {
                whitelist[addresses[i]] = true;
                whitelistArray.push(addresses[i]);
                emit AddWhitelist(addresses[i]);
            }
        }
    }

    function getWhitelistLength() public view returns (uint256) {
        return whitelistArray.length;
    }


    function removeFromWhitelist(address removedAddress) external {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        whitelist[removedAddress] = false;

        for (uint256 i = 0; i < whitelistArray.length; i++) {
            if (whitelistArray[i] == removedAddress) {
                whitelistArray[i] = whitelistArray[whitelistArray.length - 1];
                whitelistArray.pop();
                break;
            }
        }

        emit RemoveWhitelist(removedAddress);
    }

    function setMaxWhitelistAmount(uint256 _maxWhitelistAmount) public {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        maxWhitelistAmount = _maxWhitelistAmount;
    }

    function setMaxPublicContributionAmount(uint256 _maxPublicContributionAmount) public {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        maxPublicContributionAmount = _maxPublicContributionAmount;
    }

    // Finalize the fundraising and distribute tokens
    function finalizeFundraising(int24 initialTick, int24 upperTick) external {
    require(goalReached, "Fundraising goal not reached");
    require(!fundraisingFinalized, "DAO tokens already minted");
    require(daoToken != address(0), "Token not set");

    emit DebugLog("Starting finalizeFundraising");
    DaosWorldV1Token token = DaosWorldV1Token(daoToken);

    daoToken = address(token);

    // Mint and distribute tokens to all contributors
    for (uint256 i = 0; i < contributors.length; i++) {
        address contributor = contributors[i];
        uint256 contribution = contributions[contributor];
        uint256 tokensToMint = (contribution * SUPPLY_TO_FUNDRAISERS) / totalRaised;

        emit MintDetails(contributor, tokensToMint);

        token.mint(contributor, tokensToMint);
    }

    emit FundraisingFinalized(true);
    fundraisingFinalized = true;

    uint160 sqrtPriceX96 = initialTick.getSqrtRatioAtTick();
    emit DebugLog("Calculated sqrtPriceX96");
  

    INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams(
        WETH,
        address(token),
        Ticker_Velo,
        initialTick,
        upperTick,
        SUPPLY_TO_LP,
        0,
        0,
        0,
        address(this),
        block.timestamp,
        sqrtPriceX96
  
    );
    uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
    IERC20(WETH).approve(address(POSITION_MANAGER), SUPPLY_TO_LP);

    // Mint additional tokens for LP
    token.mint(address(this), SUPPLY_TO_LP);
    emit DebugLog("Minted additional tokens for LP");
    token.renounceOwnership();
    emit DebugLog("Ownership renounced");

    // Approve tokens for POSITION_MANAGER
    token.approve(address(POSITION_MANAGER), SUPPLY_TO_LP);
    emit TokenApproved(address(token), SUPPLY_TO_LP);

    (uint256 tokenId,,,) = POSITION_MANAGER.mint(params);
    emit LPTokenMinted(tokenId);

    // Deploy the liquidity locker
    address lockerAddress = liquidityLockerFactory.deploy(
        address(POSITION_MANAGER), owner(), uint64(fundExpiry), tokenId, lpFeesCut, address(this)
    );
    emit LockerDeployed(lockerAddress);

    // Transfer LP token to the locker
    POSITION_MANAGER.safeTransferFrom(address(this), lockerAddress, tokenId);
    emit TokenTransferredToLocker(tokenId, lockerAddress);

    // Initialize the locker
    ILocker(lockerAddress).initializer(tokenId);
    emit LockerInitialized(tokenId);

    liquidityLocker = lockerAddress;
    emit DebugLog("Finalize fundraising complete");
    }

    function setDaoToken(address _daoToken) external onlyOwner {
        require(_daoToken != address(0), "Invalid DAO token address");
        require(daoToken == address(0), "DAO token already set");
        daoToken = _daoToken;
    }
    
    // Allow contributors to get a refund if the goal is not reached
    function refund() external nonReentrant {
        require(!goalReached, "Fundraising goal was reached");
        require(block.timestamp > fundraisingDeadline, "Deadline not reached yet");
        require(contributions[msg.sender] > 0, "No contributions to refund");

        uint256 contributedAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;

        payable(msg.sender).transfer(contributedAmount);

        emit Refund(msg.sender, contributedAmount);
    }

    // This function is for the DAO manager to trade
    function execute(address[] calldata contracts, bytes[] calldata data, uint256[] calldata msgValues)
        external
        onlyOwner
    {
        require(fundraisingFinalized);
        require(contracts.length == data.length && data.length == msgValues.length, "Array lengths mismatch");

        for (uint256 i = 0; i < contracts.length; i++) {
            (bool success,) = contracts[i].call{value: msgValues[i]}(data[i]);
            require(success, "Call failed");
        }
    }

    function extendFundExpiry(uint256 newFundExpiry) external onlyOwner {
        require(newFundExpiry > fundExpiry, "Must choose later fund expiry");
        fundExpiry = newFundExpiry;
        ILocker(liquidityLocker).extendFundExpiry(newFundExpiry);
    }

    function extendFundraisingDeadline(uint256 newFundraisingDeadline) external {
        require(msg.sender == owner() || msg.sender == protocolAdmin, "Must be owner or protocolAdmin");
        require(!goalReached, "Fundraising goal was reached");
        require(newFundraisingDeadline > fundraisingDeadline, "new fundraising deadline must be > old one");
        fundraisingDeadline = newFundraisingDeadline;
    }

    function emergencyEscape() external {
        require(msg.sender == protocolAdmin, "must be protocol admin");
        require(!fundraisingFinalized, "fundraising already finalized");
        (bool success,) = protocolAdmin.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // Fallback function to make contributions simply by sending ETH to the contract
    receive() external payable {
        if (!goalReached && block.timestamp < fundraisingDeadline) {
            contribute();
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
