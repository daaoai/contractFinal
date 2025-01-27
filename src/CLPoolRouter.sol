// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20Minimal.sol";

import "./interfaces/callback/ICLSwapCallback.sol";
import "./interfaces/ICLPool.sol";

contract CLPoolRouter is ICLSwapCallback {
    int256 private _amount0Delta;
    int256 private _amount1Delta;

    // Events for better tracking
    event SwapExecuted(
        address indexed pool,
        address indexed sender,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        int256 amount0Delta,
        int256 amount1Delta
    );

    event ApprovalHandled(
        address indexed token,
        address indexed owner,
        uint256 amount
    );

    // Internal function to handle token approval
    function _handleApproval(address token, uint256 amount) internal {
        IERC20Minimal tokenContract = IERC20Minimal(token);
        uint256 currentAllowance = tokenContract.allowance(
            msg.sender,
            address(this)
        );

        if (currentAllowance < amount) {
            // If current allowance is not zero but less than required, reset it
            if (currentAllowance > 0) {
                tokenContract.approve(address(this), 0);
            }
            // Approve the required amount
            require(
                tokenContract.approve(address(this), amount),
                "Approval failed"
            );

            emit ApprovalHandled(token, msg.sender, amount);
        }
    }

    function getSwapResult(
        address pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    )
        external
        returns (
            int256 amount0Delta,
            int256 amount1Delta,
            uint160 nextSqrtRatio
        )
    {
        // Get token that needs approval
        address token = zeroForOne
            ? ICLPool(pool).token0()
            : ICLPool(pool).token1();
        uint256 amount = uint256(
            amountSpecified > 0 ? amountSpecified : -amountSpecified
        );

        // Handle approval internally
        _handleApproval(token, amount);

        // ================================================= //
        (amount0Delta, amount1Delta) = ICLPool(pool).swap(
            address(0),
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            abi.encode(msg.sender)
        );

        (nextSqrtRatio, , , , , ) = ICLPool(pool).slot0();
        // ================================================= //

        emit SwapExecuted(
            pool,
            msg.sender,
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            amount0Delta,
            amount1Delta
        );
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        address sender = abi.decode(data, (address));

        if (amount0Delta > 0) {
            IERC20Minimal(ICLPool(msg.sender).token0()).transferFrom(
                sender,
                msg.sender,
                uint256(amount0Delta)
            );
        } else if (amount1Delta > 0) {
            IERC20Minimal(ICLPool(msg.sender).token1()).transferFrom(
                sender,
                msg.sender,
                uint256(amount1Delta)
            );
        }
    }
}
