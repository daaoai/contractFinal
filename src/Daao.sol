// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DaaoToken} from "./DaaoToken.sol";
import {ICLPool} from "./interfaces/ICLPool.sol";
import {ICLFactory} from "./interfaces/ICLFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {IERC721Receiver} from "./LPLocker/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH, INonfungiblePositionManager, IVelodromeFactory, ILockerFactory, ILocker} from "./interface.sol";
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract Daao is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using TickMath for int24;

    enum WhitelistTier {
        None,
        Platinum,
        Gold,
        Silver
    }

    struct WhitelistInfo {
        WhitelistTier tier;
        uint256 addedAt;
        bool isActive;
    }

    mapping(address => WhitelistInfo) private whitelistInfo;
    uint256 private whitelistedCount;

    uint256 public constant LP_PERCENTAGE = 10;
    uint256 public constant TREASURY_PERCENTAGE = 90;
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18; // 1 billion total supply
    uint256 public constant POOL_PERCENTAGE = 10; // 10% for pool
    uint256 public constant CONTRIBUTORS_PERCENTAGE = 90; // 90% for contributors
    uint256 public constant SUPPLY_TO_FUNDRAISERS =
        (TOTAL_SUPPLY * CONTRIBUTORS_PERCENTAGE) / 100; // 900 million tokens

    uint256 public GOLD_DEFAULT_LIMIT = 0.5 ether;
    uint256 public SILVER_DEFAULT_LIMIT = 0.1 ether;
    uint256 public PLATINUM_DEFAULT_LIMIT = 1 ether;

    IVelodromeFactory public constant VELODROME_FACTORY =
        IVelodromeFactory(0x04625B046C69577EfC40e6c0Bb83CDBAfab5a55F);
    INonfungiblePositionManager public constant POSITION_MANAGER =
        INonfungiblePositionManager(0x991d5546C4B442B4c5fdc4c8B8b8d131DEB24702);
    address public constant MODE = 0xDfc7C877a950e49D2610114102175A06C2e3167a;
    ILockerFactory public liquidityLockerFactory;
    address public liquidityLocker;

    int24 private constant TICK_SPACING = 100;
    uint256 public totalRaised;
    uint256 public fundraisingGoal;
    bool public fundraisingFinalized;
    bool public goalReached;
    uint256 public fundraisingDeadline;
    uint256 public fundExpiry;
    uint8 public lpFeesCut = 60;
    address public protocolAdmin;
    string public name;
    string public symbol;
    address public daoToken;

    // The amount of ETH you've contributed
    mapping(WhitelistTier => uint256) public tierLimits;
    mapping(address => uint256) public contributions;
    
    mapping(uint256 => address) public contributorIndex;
    uint256 public contributorsCount;

    event DebugLog(string message);
    event RemoveWhitelist(address);
    event LPTokenMinted(uint256 tokenId);
    event PoolCreated(address indexed pool);
    event LockerInitialized(uint256 tokenId);
    event FundraisingFinalized(bool success);
    event PoolInitialized(uint160 sqrtPriceX96);
    event LockerDeployed(address indexed lockerAddress);
    event Refund(address indexed contributor, uint256 amount);
    event UpdateWhitelist(address indexed user, WhitelistTier tier);
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
        address _protocolAdmin
    ) Ownable(_daoManager) {
        require(
            _fundraisingGoal > 0,
            "Fundraising goal must be greater than 0"
        );
        require(
            _fundraisingDeadline > block.timestamp,
            "Deadline must be in the future"
        );
        require(
            _fundExpiry > _fundraisingDeadline,
            "Fund expiry must be greater than fundraising deadline"
        );
        name = _name;
        symbol = _symbol;
        fundraisingGoal = _fundraisingGoal;
        fundraisingDeadline = _fundraisingDeadline;
        fundExpiry = _fundExpiry;
        liquidityLockerFactory = ILockerFactory(_liquidityLockerFactory);
        protocolAdmin = _protocolAdmin;

        // Teir allocation
        tierLimits[WhitelistTier.Platinum] = PLATINUM_DEFAULT_LIMIT;
        tierLimits[WhitelistTier.Gold] = GOLD_DEFAULT_LIMIT;
        tierLimits[WhitelistTier.Silver] = SILVER_DEFAULT_LIMIT;
    }

    function contribute(uint256 _amount) public payable nonReentrant {
        require(!goalReached, "Goal already reached");
        require(block.timestamp < fundraisingDeadline, "Deadline hit");
        require(_amount > 0, "Contribution must be greater than 0");

        // Must be whitelisted
        WhitelistInfo memory userInfo = whitelistInfo[msg.sender];
        require(userInfo.isActive && userInfo.tier != WhitelistTier.None, "Not whitelisted");
        
        // Contribution must below teir limit
        uint256 userLimit = tierLimits[userInfo.tier];

        require(
            contributions[msg.sender] + _amount <= userLimit,
            "Exceeding tier limit"
        );

        uint256 effectiveContribution = _amount;
        if (totalRaised + _amount > fundraisingGoal) {
            effectiveContribution = fundraisingGoal - totalRaised;
        }

        if (effectiveContribution > 0) {
            SafeERC20.safeTransferFrom(IERC20(MODE), msg.sender, address(this), effectiveContribution);

            if (contributions[msg.sender] == 0) {
                contributorIndex[contributorsCount] = msg.sender;
                contributorsCount++;
            }
        }

        contributions[msg.sender] += effectiveContribution;
        totalRaised += effectiveContribution;

        if(totalRaised >= fundraisingGoal) {
            goalReached = true;
        }

        emit Contribution(msg.sender, effectiveContribution);
    }

    function addOrUpdateWhitelist(
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
            address user = _addresses[i];
            WhitelistTier newTier = _tiers[i];

            require(user != address(0), "Invalid address");
            require(newTier != WhitelistTier.None, "Invalid tier");

            if (!whitelistInfo[user].isActive) {
                whitelistedCount++;
            }

            whitelistInfo[user] = WhitelistInfo({
                tier: newTier,
                addedAt: block.timestamp,
                isActive: true
            });

            emit UpdateWhitelist(_addresses[i], _tiers[i]);
        }
    }

    function getWhitelistLength() public view returns (uint256) {
        return whitelistedCount;
    }

    function getWhitelistInfo(address _user) public view returns (bool isActive, WhitelistTier tier, uint256 addedAt) {
        WhitelistInfo memory info = whitelistInfo[_user];
        return (info.isActive, info.tier, info.addedAt);
    }

    function removeFromWhitelist(address removedAddress) external {
        require(
            msg.sender == owner() || msg.sender == protocolAdmin,
            "Must be owner or protocolAdmin"
        );

        require(removedAddress != address(0), "Invalid address");

        WhitelistInfo storage _userInfo = whitelistInfo[removedAddress];
        require(
            _userInfo.isActive,
            "Address not whitelisted"
        );
        _userInfo.isActive = false;
        _userInfo.tier = WhitelistTier.None;
        whitelistedCount--;

        emit RemoveWhitelist(removedAddress);
    }

    function updateTierLimit(WhitelistTier _tier, uint256 _newLimit) external {
        require(
            msg.sender == owner() || msg.sender == protocolAdmin,
            "Not authorized"
        );
        require(_tier != WhitelistTier.None, "Invalid tier");
        require(_newLimit <= fundraisingGoal, "Invalid limit");

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

    //Finalize the fundraising and distribute tokens
    function finalizeFundraising(uint256 amount0Min, uint256 amount1Min) external{
        require(
            msg.sender == owner() || msg.sender == protocolAdmin,
            "Not authorized"
        );
        require(goalReached, "Fundraising goal not reached");
        require(!fundraisingFinalized, "DAO tokens already minted");

        DaaoToken token = new DaaoToken(name, symbol);
        daoToken = address(token);

        fundraisingFinalized = true;
        // Mint and distribute tokens to all contributors
        for (uint256 i = 0; i < contributorsCount; i++) {
            address contributor = contributorIndex[i];
            uint256 contribution = contributions[contributor];
            if(contribution > 0) {
                uint256 tokensToMint = (contribution * SUPPLY_TO_FUNDRAISERS) /
                    totalRaised;
                token.mint(contributor, tokensToMint);
                emit MintDetails(contributor, tokensToMint);
            }
        }

        // ADD THE NEW CODE RIGHT HERE, AFTER TOKEN DISTRIBUTION BUT BEFORE POOL CREATION
        uint256 totalModeCollected = IERC20(MODE).balanceOf(address(this));
        uint256 modeTokensForLP = (totalModeCollected * LP_PERCENTAGE) / 100; // 10% of WETH for LP
        uint256 daoTokensForLP = (TOTAL_SUPPLY * POOL_PERCENTAGE) / 100; // 10% of tokens for LP
        uint256 modeTokensForTreasury = totalModeCollected - modeTokensForLP;

        //Transfer the remaining MODE tokens to the owner
        SafeERC20.safeTransfer(IERC20(MODE), owner(), modeTokensForTreasury);

        uint256 amountToken0ForLP;
        uint256 amountToken1ForLP;

        if(daoToken < address(MODE)){
            token0 = daoToken;
            token1 = address(MODE);
            amountToken0ForLP = daoTokensForLP;
            amountToken1ForLP = modeTokensForLP;
        } else {
            token0 = address(MODE);
            token1 = daoToken;
            amountToken0ForLP = modeTokensForLP;
            amountToken1ForLP = daoTokensForLP;
        }

        uint256 price = FullMath.mulDiv(amountToken1ForLP, 1 << 96, amountToken0ForLP);  // Multiply by 2^96 first
        uint160 sqrtPriceX96 = uint160(Math.sqrt(price) * (1 << 48));  // Then multiply sqrt by 2^48 (half of 96)

        int24 initialTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        int24 tickSpacedLower = int24((initialTick - TICK_SPACING * 1000) / TICK_SPACING) * TICK_SPACING;
        int24 tickSpacedUpper = int24((initialTick + TICK_SPACING * 1000) / TICK_SPACING) * TICK_SPACING;

        token.mint(address(this), daoTokensForLP);
        token.renounceOwnership();
        SafeERC20.safeIncreaseAllowance(IERC20(token0), address(POSITION_MANAGER), amountToken0ForLP);
        SafeERC20.safeIncreaseAllowance(IERC20(token1), address(POSITION_MANAGER), amountToken1ForLP);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams(
                token0,
                token1,
                TICK_SPACING,
                tickSpacedLower,
                tickSpacedUpper,
                amountToken0ForLP,
                amountToken1ForLP,
                amount0Min,
                amount1Min,
                address(this),
                block.timestamp,
                sqrtPriceX96
            );
        (uint256 tokenId, , uint256 amount0Minted, uint256 amount1Minted) = POSITION_MANAGER.mint(params);
        emit LPTokenMinted(tokenId);

        if(amount0Minted < amountToken0ForLP){
            SafeERC20.safeTransfer(IERC20(token0), owner(), amountToken0ForLP - amount0Minted);
        }
        if(amount1Minted < amountToken1ForLP){
            SafeERC20.safeTransfer(IERC20(token1), owner(), amountToken1ForLP - amount1Minted);
        }

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
        emit FundraisingFinalized(true);
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
        totalRaised -= contributedAmount;

        SafeERC20.safeTransfer(IERC20(MODE), msg.sender, contributedAmount);

        emit Refund(msg.sender, contributedAmount);
    }

    // This function is for the DAO manager to trade
    function execute(
        address[] calldata contracts,
        bytes[] calldata data,
        uint256[] calldata approveAmounts
    ) external onlyOwner {
        require(fundraisingFinalized, "fundraisingFinalized is false");
        require(
            contracts.length == data.length && data.length == approveAmounts.length,
            "Array lengths mismatch"
        );

        for (uint256 i = 0; i < contracts.length; i++) {
            if(approveAmounts[i] > 0) {
                SafeERC20.safeIncreaseAllowance(IERC20(MODE), contracts[i], approveAmounts[i]);
            }
            (bool success, ) = contracts[i].call(data[i]);
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
        require(block.timestamp <= fundraisingDeadline, "can not extend deadline after deadline is passed");
        require(
            newFundraisingDeadline > fundraisingDeadline,
            "new fundraising deadline must be > old one"
        );
        fundraisingDeadline = newFundraisingDeadline;
    }

    function emergencyEscape() external {
        require(msg.sender == protocolAdmin, "must be protocol admin");
        require(!fundraisingFinalized, "fundraising already finalized");
        SafeERC20.safeTransfer(IERC20(MODE), protocolAdmin, IERC20(MODE).balanceOf(address(this)));
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
