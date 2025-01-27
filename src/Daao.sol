// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DaaoToken} from "./DaaoToken.sol";
import {ICLPool} from "./interfaces/ICLPool.sol";
import {ICLFactory} from "./interfaces/ICLFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TickMath} from "v3-core/libraries/TickMath.sol";
import {IERC721Receiver} from "./LPLocker/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {INonfungiblePositionManager, IVelodromeFactory, ILockerFactory, ILocker} from "./interface.sol";

contract Daao is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using TickMath for int24;

    enum WhitelistTier {
        None,
        Platinum,
        Gold,
        Silver
    }

    uint24 public constant UNI_V3_FEE = 500;
    int24 public constant TICKING_SPACE = 100;
    uint256 public constant LP_PERCENTAGE = 10;
    uint256 public constant TREASURY_PERCENTAGE = 90;
    uint256 public GOLD_DEFAULT_LIMIT = 0.5 ether;
    uint256 public SILVER_DEFAULT_LIMIT = 0.1 ether;
    uint256 public PLATINUM_DEFAULT_LIMIT = 1 ether;
    uint256 public constant WETH_SUPPLY_TO_LP = 0.00001 ether;
    uint256 public constant TOKEN_SUPPLY_TO_LP = 0.00002 ether;

    IVelodromeFactory public constant Velodrome_factory =
        IVelodromeFactory(0x04625B046C69577EfC40e6c0Bb83CDBAfab5a55F);
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

    address public secondToken;

    // If maxWhitelistAmount > 0, then its whitelist only. And this is the max amount you can contribute.
    uint256 public maxWhitelistAmount;
    // If maxPublicContributionAmount > 0, then you cannot contribute more than this in public rounds.
    uint256 public maxPublicContributionAmount;

    // The amount of ETH you've contributed
    mapping(WhitelistTier => uint256) public tierLimits;
    mapping(address => WhitelistTier) public userTiers;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public whitelist;
    address[] public whitelistArray;
    address[] public contributors;

    event DebugLog(string message);
    event RemoveWhitelist(address);
    event LPTokenMinted(uint256 tokenId);
    event PoolCreated(address indexed pool);
    event LockerInitialized(uint256 tokenId);
    event FundraisingFinalized(bool success);
    event PoolInitialized(uint160 sqrtPriceX96);
    event LockerDeployed(address indexed lockerAddress);
    event Refund(address indexed contributor, uint256 amount);
    event TokenApproved(address indexed token, uint256 amount);
    event AddWhitelist(address indexed user, WhitelistTier tier);
    event Contribution(address indexed contributor, uint256 amount);
    event MintDetails(address indexed contributor, uint256 tokensToMint);
    event TierLimitUpdated(WhitelistTier indexed teir, uint256 _newLimit);
    event TokenTransferredToLocker(uint256 tokenId, address lockerAddress);
    event MintParamsCreated(
        uint256 tokenId,
        address token0,
        address token1,
        uint256 liquidity
    );
    address public token0;
    address public token1;

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
        require(
            _fundraisingGoal > 0,
            "Fundraising goal must be greater than 0"
        );
        require(
            _fundraisingDeadline > block.timestamp,
            "_fundraisingDeadline > block.timestamp"
        );
        require(
            _fundExpiry > fundraisingDeadline,
            "_fundExpiry > fundraisingDeadline"
        );
        name = _name;
        symbol = _symbol;
        fundraisingGoal = _fundraisingGoal;
        fundraisingDeadline = _fundraisingDeadline;
        fundExpiry = _fundExpiry;
        liquidityLockerFactory = ILockerFactory(_liquidityLockerFactory);
        maxWhitelistAmount = _maxWhitelistAmount;
        protocolAdmin = _protocolAdmin;
        maxPublicContributionAmount = _maxPublicContributionAmount;

        // Teir allocation
        tierLimits[WhitelistTier.Platinum] = PLATINUM_DEFAULT_LIMIT;
        tierLimits[WhitelistTier.Gold] = GOLD_DEFAULT_LIMIT;
        tierLimits[WhitelistTier.Silver] = SILVER_DEFAULT_LIMIT;
    }

    function contribute() public payable nonReentrant {
        require(!goalReached, "Goal already reached");
        require(block.timestamp < fundraisingDeadline, "Deadline hit");
        require(msg.value > 0, "Contribution must be greater than 0");

        // Must be whitelisted
        WhitelistTier userTier = userTiers[msg.sender];
        require(userTier != WhitelistTier.None, "Not whitelisted");
        // Contribution must boolow teir limit
        uint256 userLimit = tierLimits[userTier];
        require(
            contributions[msg.sender] + msg.value <= userLimit,
            "Exceeding tier limit"
        );

        if (maxWhitelistAmount > 0) {
            require(
                contributions[msg.sender] + msg.value <= maxWhitelistAmount,
                "Exceeding maxWhitelistAmount"
            );
        } else if (maxPublicContributionAmount > 0) {
            require(
                contributions[msg.sender] + msg.value <=
                    maxPublicContributionAmount,
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

        if (totalRaised == fundraisingGoal) {
            goalReached = true;
        }

        emit Contribution(msg.sender, effectiveContribution);
    }

    function addToWhitelist(
        address[] calldata _addresses,
        WhitelistTier[] calldata _tiers
    ) external {
        require(
            msg.sender == owner() || msg.sender == protocolAdmin,
            "Must be owner or protocolAdmin"
        );
        require(_addresses.length == _tiers.length, "Arrays length mismatch");
        require(_addresses.length > 0, "Empty arrays");

        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Invalid address");
            require(_tiers[i] != WhitelistTier.None, "Invalid tier");

            userTiers[_addresses[i]] = _tiers[i];

            // if (!whitelist[_addresses[i]]) {
            //     whitelist[_addresses[i]] = true;
            //     whitelistArray.push(_addresses[i]);
            // }
            emit AddWhitelist(_addresses[i], _tiers[i]);
        }
    }

    function updateTierLimit(WhitelistTier _tier, uint256 _newLimit) external {
        require(
            msg.sender == owner() || msg.sender == protocolAdmin,
            "Not authorized"
        );
        require(_tier != WhitelistTier.None, "Invalid tier");
        require(_newLimit > 0, "Invalid limit");

        tierLimits[_tier] = _newLimit;

        if (_tier == WhitelistTier.Gold) {
            GOLD_DEFAULT_LIMIT = _newLimit;
        } else if (_tier == WhitelistTier.Silver) {
            SILVER_DEFAULT_LIMIT = _newLimit;
        } else {
            PLATINUM_DEFAULT_LIMIT = _newLimit;
        }

        emit TierLimitUpdated(_tier, _newLimit);
    }

    function getWhitelistLength() public view returns (uint256) {
        return whitelistArray.length;
    }

    function removeFromWhitelist(address removedAddress) external {
        require(
            msg.sender == owner() || msg.sender == protocolAdmin,
            "Must be owner or protocolAdmin"
        );

        require(removedAddress != address(0), "Invalid address");
        require(
            userTiers[removedAddress] != WhitelistTier.None,
            "Address not whitelisted"
        );
        userTiers[removedAddress] = WhitelistTier.None;

        // whitelist[removedAddress] = false;

        // for (uint256 i = 0; i < whitelistArray.length; i++) {
        //     if (whitelistArray[i] == removedAddress) {
        //         whitelistArray[i] = whitelistArray[whitelistArray.length - 1];
        //         whitelistArray.pop();
        //         break;
        //     }
        // }

        emit RemoveWhitelist(removedAddress);
    }

    function setMaxWhitelistAmount(uint256 _maxWhitelistAmount) public {
        require(
            msg.sender == owner() || msg.sender == protocolAdmin,
            "Must be owner or protocolAdmin"
        );
        maxWhitelistAmount = _maxWhitelistAmount;
    }

    function setMaxPublicContributionAmount(
        uint256 _maxPublicContributionAmount
    ) public {
        require(
            msg.sender == owner() || msg.sender == protocolAdmin,
            "Must be owner or protocolAdmin"
        );
        maxPublicContributionAmount = _maxPublicContributionAmount;
    }

    //Finalize the fundraising and distribute tokens
    function finalizeFundraising(int24 initialTick, int24 upperTick) external {
        require(goalReached, "Fundraising goal not reached");
        require(!fundraisingFinalized, "DAO tokens already minted");
        require(daoToken != address(0), "Token not set");

        require(secondToken != address(0), "secondToken not set");
        emit DebugLog("Starting finalizeFundraising");
        DaaoToken token = DaaoToken(daoToken);
        daoToken = address(token);

        // Mint and distribute tokens to all contributors
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 contribution = contributions[contributor];
            uint256 tokensToMint = (contribution * SUPPLY_TO_FUNDRAISERS) /
                totalRaised;

            emit MintDetails(contributor, tokensToMint);

            token.mint(contributor, tokensToMint);
        }

        // ADD THE NEW CODE RIGHT HERE, AFTER TOKEN DISTRIBUTION BUT BEFORE POOL CREATION
        uint256 totalCollected = address(this).balance;
        uint256 amountForLP = (totalCollected * LP_PERCENTAGE) / 100;
        uint256 amountForTreasury = totalCollected - amountForLP;
        // Transfer treasury amount to owner (We are left with LP amount)
        (bool success, ) = owner().call{value: amountForTreasury}("");
        require(success, "Treasury transfer failed");

        emit FundraisingFinalized(true);
        fundraisingFinalized = true;

        int24 iprice = 7000;
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(iprice);
        emit DebugLog("Calculated sqrtPriceX96");

        address token0;
        address token1;

        if (daoToken < secondToken) {
            token0 = daoToken;
            token1 = secondToken;
        } else {
            token0 = secondToken;
            token1 = daoToken;
        }

        uint256 amountToken0ForLP = amountForLP; // For first token
        uint256 amountToken1ForLP = amountForLP;

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams(
                token0,
                token1,
                TICKING_SPACE,
                initialTick,
                upperTick,
                amountToken0ForLP,
                amountToken1ForLP,
                0,
                0,
                address(this),
                block.timestamp,
                sqrtPriceX96
            );
        // uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        // IERC20(WETH).approve(address(POSITION_MANAGER), WETH_SUPPLY_TO_LP);

        if (token0 == address(token)) {
            // If token0 is the DAO token we control
            token.mint(address(this), amountToken0ForLP);
        } else {
            // If you have a custom ERC20 secondToken, you'd handle it similarly
            // Example:
            DaaoToken(secondToken).mint(address(this), amountToken0ForLP);
        }

        if (token1 == address(token)) {
            // If token1 is the DAO token
            token.mint(address(this), amountToken1ForLP);
        } else {
            // If secondToken is token1
            DaaoToken(secondToken).mint(address(this), amountToken1ForLP);
        }

        token.renounceOwnership();
        IERC20(token0).approve(address(POSITION_MANAGER), amountToken0ForLP);
        IERC20(token1).approve(address(POSITION_MANAGER), amountToken1ForLP);
        // Mint additional tokens for LP
        // Mint -> this (X)
        // (X) => 0x00000000
        //
        // token.mint(address(this), TOKEN_SUPPLY_TO_LP);
        emit DebugLog("Minted additional tokens for LP");
        // token.renounceOwnership();
        emit DebugLog("Ownership renounced");

        // Approve tokens for POSITION_MANAGER
        // token.approve(address(POSITION_MANAGER), TOKEN_SUPPLY_TO_LP);
        // emit TokenApproved(address(token), TOKEN_SUPPLY_TO_LP);

        (uint256 tokenId, , , ) = POSITION_MANAGER.mint(params);
        emit LPTokenMinted(tokenId);

        // Deploy the liquidity locker
        address lockerAddress = liquidityLockerFactory.deploy(
            address(POSITION_MANAGER),
            owner(),
            uint64(fundExpiry),
            tokenId,
            lpFeesCut,
            address(this)
        );
        emit LockerDeployed(lockerAddress);

        // Transfer LP token to the locker
        POSITION_MANAGER.safeTransferFrom(
            address(this),
            lockerAddress,
            tokenId
        );
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

    function setSecondToken(address _daoToken) external onlyOwner {
        require(_daoToken != address(0), "Invalid second token address");
        require(secondToken == address(0), "DAO token already set");
        secondToken = _daoToken;
    }

    // Allow contributors to get a refund if the goal is not reached
    function refund() external nonReentrant {
        require(!goalReached, "Fundraising goal was reached");
        require(
            block.timestamp > fundraisingDeadline,
            "Deadline not reached yet"
        );
        require(contributions[msg.sender] > 0, "No contributions to refund");

        uint256 contributedAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;

        payable(msg.sender).transfer(contributedAmount);

        emit Refund(msg.sender, contributedAmount);
    }

    // This function is for the DAO manager to trade
    function execute(
        address[] calldata contracts,
        bytes[] calldata data,
        uint256[] calldata msgValues
    ) external onlyOwner {
        require(fundraisingFinalized);
        require(
            contracts.length == data.length && data.length == msgValues.length,
            "Array lengths mismatch"
        );

        for (uint256 i = 0; i < contracts.length; i++) {
            (bool success, ) = contracts[i].call{value: msgValues[i]}(data[i]);
            require(success, "Call failed");
        }
    }

    function extendFundExpiry(uint256 newFundExpiry) external onlyOwner {
        require(newFundExpiry > fundExpiry, "Must choose later fund expiry");
        fundExpiry = newFundExpiry;
        ILocker(liquidityLocker).extendFundExpiry(newFundExpiry);
    }

    function extendFundraisingDeadline(
        uint256 newFundraisingDeadline
    ) external {
        require(
            msg.sender == owner() || msg.sender == protocolAdmin,
            "Must be owner or protocolAdmin"
        );
        require(!goalReached, "Fundraising goal was reached");
        require(
            newFundraisingDeadline > fundraisingDeadline,
            "new fundraising deadline must be > old one"
        );
        fundraisingDeadline = newFundraisingDeadline;
    }

    function emergencyEscape() external {
        require(msg.sender == protocolAdmin, "must be protocol admin");
        require(!fundraisingFinalized, "fundraising already finalized");
        (bool success, ) = protocolAdmin.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // Fallback function to make contributions simply by sending ETH to the contract
    receive() external payable {
        if (!goalReached && block.timestamp < fundraisingDeadline) {
            contribute();
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
