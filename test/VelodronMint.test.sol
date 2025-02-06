// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IWETH, INonfungiblePositionManager, IVelodromeFactory, ILockerFactory, ILocker} from "../src/interface.sol";
import {DaaoToken} from "../src/DaaoToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";

interface IVeloPool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            bool unlocked
        );
}
contract VelodronMintTest is Test {

    IVelodromeFactory public constant Velodrome_factory =
        IVelodromeFactory(0x04625B046C69577EfC40e6c0Bb83CDBAfab5a55F);
    INonfungiblePositionManager public constant POSITION_MANAGER =
        INonfungiblePositionManager(0x991d5546C4B442B4c5fdc4c8B8b8d131DEB24702);
    IERC20 public constant MODE = IERC20(0xDfc7C877a950e49D2610114102175A06C2e3167a);

    address constant USER_MODE_WHALE = 0x9cBd6d7B3f7377365E45CF53937E96ed8b92E53d;
    int24 constant TICK_SPACING = 100;

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function test_mint() public {
        vm.prank(USER_MODE_WHALE);
        MODE.transfer(address(this), 1 ether);

        DaaoToken token = new DaaoToken{salt: bytes32(uint256(0x18EF))}("Daao", "DAO");
        token.mint(address(this), 100_000_000 ether);

        // Calculate amounts for LP
        uint256 modeForLP = MODE.balanceOf(address(this)); 
        uint256 tokensForLP = token.balanceOf(address(this));

        // Calculate initial price based on the ratio of tokens
        // Price = (amount1 / 10^decimals1) / (amount0 / 10^decimals0)
        // uint256 price = (modeForLP * 1e18) / tokensForLP;
        // int24 initialTick = TickMath.getTickAtSqrtRatio(
        //     uint160(sqrt((price << 192)))
        // );
        // uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(initialTick);


        // Determine token ordering
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint256 price;
        int24 initialTick;
        uint160 sqrtPriceX96;

        if (address(token) < address(MODE)) {
            console.log("DaaoToken is token0, MODE is token1");
            // Case 1: DaaoToken is token0, MODE is token1
            token0 = address(token);
            token1 = address(MODE);
            amount0 = tokensForLP;
            amount1 = modeForLP;
            // price = (modeForLP * 1e18) / tokensForLP;  
            // // sqrtPriceX96 = uint160(sqrt(price) * (1 << 96));
            // uint256 ratioX192 = FullMath.mulDiv(modeForLP, 1 << 192, tokensForLP);
            // sqrtPriceX96 = uint160(sqrt(ratioX192));

            uint256 price = FullMath.mulDiv(amount1, 1 << 96, amount0);  // Multiply by 2^96 first
            sqrtPriceX96 = uint160(sqrt(price) * (1 << 48));  // Then multiply sqrt by 2^48 (half of 96)
        } else {
            console.log("MODE is token0, DaaoToken is token1");
            // Case 2: MODE is token0, DaaoToken is token1
            token0 = address(MODE);
            token1 = address(token);
            amount0 = modeForLP;
            amount1 = tokensForLP;
            price = (tokensForLP * 1e18) / modeForLP;
            // sqrtPriceX96 = uint160(sqrt(price) * (1 << 96));
            uint256 ratioX192 = FullMath.mulDiv(tokensForLP, 1 << 192, modeForLP);
            sqrtPriceX96 = uint160(sqrt(ratioX192));
        }
        console.log("price:", price);

        initialTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("Amount0:", amount0);
        console.log("Amount1:", amount1);
        console.log("Initial tick:", initialTick);
        console.log("sqrt price X96:", sqrtPriceX96);
        console.log("price:", TICK_SPACING);

        // Approve tokens
        token.approve(address(POSITION_MANAGER), tokensForLP);
        MODE.approve(address(POSITION_MANAGER), modeForLP);

        int24 tickSpacedLower = int24((initialTick - TICK_SPACING * 10) / TICK_SPACING) * TICK_SPACING;
        int24 tickSpacedUpper = int24((initialTick + TICK_SPACING * 10) / TICK_SPACING) * TICK_SPACING;

        // Create position parameters
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams(
            token0,
            token1,
            TICK_SPACING,
            tickSpacedLower,
            tickSpacedUpper,
            amount0,
            amount1,
            0, // No minimum amounts for testing
            0,
            address(this),
            block.timestamp,
            sqrtPriceX96
        );

        // Mint position
        (uint256 tokenId, uint128 liquidity, uint256 amount0Used, uint256 amount1Used) = 
            POSITION_MANAGER.mint(params);

        console.log("NFT Token ID:", tokenId);
        console.log("Liquidity:", liquidity);
        console.log("Amount0 used:", amount0Used);
        console.log("Amount1 used:", amount1Used);

        IVeloPool _pool = IVeloPool(Velodrome_factory.getPool(token0, token1, TICK_SPACING));

        (uint160 sqrtPriceX961, , , , , ) = _pool.slot0();
        uint256 priceX192 = uint256(sqrtPriceX961) * (sqrtPriceX961);
        price = FullMath.mulDiv(priceX192, 1e18, 1 << 192);
        console.log("price final: ", price);

    //     // Verify position was created
    //     assertTrue(tokenId > 0, "Position not created");
    //     assertTrue(liquidity > 0, "No liquidity added");
    //     assertTrue(POSITION_MANAGER.ownerOf(tokenId) == address(this), "Wrong position owner");
    }
}