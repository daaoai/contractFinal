// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICLPool.sol";
import "./interfaces/IERC20Minimal.sol";
import "./interfaces/callback/ICLSwapCallback.sol";

contract CLPoolRouter is ICLSwapCallback {
    int256 private _amount0Delta;
    int256 private _amount1Delta;

    event SwapExecuted(
        address indexed pool,
        address indexed sender,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        int256 amount0Delta,
        int256 amount1Delta,
        uint256 outputAmount
    );

    event ApprovalHandled(
        address indexed token,
        address indexed owner,
        uint256 amount
    );

    function checkApproval(
        address token,
        address owner
    ) external view returns (uint256) {
        return IERC20Minimal(token).allowance(owner, address(this));
    }

    function _handleApproval(address token, uint256 amount) internal {
        IERC20Minimal tokenContract = IERC20Minimal(token);
        uint256 currentAllowance = tokenContract.allowance(
            msg.sender,
            address(this)
        );

        if (currentAllowance < amount) {
            if (currentAllowance > 0) {
                tokenContract.approve(address(this), 0);
            }

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
        address tokenIn = zeroForOne
            ? ICLPool(pool).token0()
            : ICLPool(pool).token1();
        address tokenOut = zeroForOne
            ? ICLPool(pool).token1()
            : ICLPool(pool).token0();
        uint256 amount = uint256(
            amountSpecified > 0 ? amountSpecified : -amountSpecified
        );

        _handleApproval(tokenIn, amount);

        IERC20Minimal(tokenIn).transferFrom(msg.sender, pool, amount);

        (amount0Delta, amount1Delta) = ICLPool(pool).swap(
            address(this),
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            abi.encode(msg.sender)
        );

        (nextSqrtRatio, , , , , ) = ICLPool(pool).slot0();
        uint256 outputAmount;
        if (zeroForOne) {
            require(amount1Delta < 0, "Invalid amount1Delta");
            outputAmount = uint256(-amount1Delta);
        } else {
            require(amount0Delta < 0, "Invalid amount0Delta");
            outputAmount = uint256(-amount0Delta);
        }

        if (outputAmount > 0) {
            uint256 poolBalance = IERC20Minimal(tokenOut).balanceOf(
                address(this)
            );
            require(
                poolBalance >= outputAmount,
                "Insufficient pool balance for output"
            );
            IERC20Minimal(tokenOut).transfer(msg.sender, outputAmount);
        }

        emit SwapExecuted(
            pool,
            msg.sender,
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            amount0Delta,
            amount1Delta,
            outputAmount
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
