// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        int24 tickSpacing;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
        uint160 sqrtPriceX96;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);

    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IVelodromeFactory {
    function createPool(
        address tokenA,
        address tokenB,
        int24 tickSpacing,
        uint160 sqrtPriceX96
    ) external returns (address pool);
}

interface ILockerFactory {
    function deploy(
        address token,
        address beneficiary,
        uint256 durationSeconds,
        uint256 tokenId,
        uint256 fees,
        address daoTreasury
    ) external payable returns (address);
}

interface ILocker {
    function initializer(uint256 tokenId) external;

    function extendFundExpiry(uint256 fundExpiry) external;
}

struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

interface IWETH is IERC20 {
    /// @notice Deposit ETH and get back WETH in return
    function deposit() external payable;

    /// @notice Withdraw WETH and get back ETH
    /// @param wad The amount of WETH to withdraw (in wei)
    function withdraw(uint256 wad) external;
}

interface ISwapRouter {
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}
