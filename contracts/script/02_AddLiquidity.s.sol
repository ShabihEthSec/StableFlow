// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

import {BaseScript} from "./base/BaseScript.sol";
import {LiquidityHelpers} from "./base/LiquidityHelpers.sol";

contract AddLiquidityScript is BaseScript, LiquidityHelpers {
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    /////////////////////////////////////
    // --- Configure These ---
    /////////////////////////////////////

    uint24 lpFee = 3000; // 0.30%
    int24 tickSpacing = 60;

    // --- liquidity position configuration --- //
    uint256 public token0Amount = 1e17;
    uint256 public token1Amount = 6e6;

    /////////////////////////////////////

    int24 tickLower;
    int24 tickUpper;

    int24 constant MIN_TICK = TickMath.MIN_TICK;
    int24 constant MAX_TICK = TickMath.MAX_TICK;


    function run() external {
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: lpFee,
            tickSpacing: tickSpacing,
            hooks: hookContract
        });
        bytes memory hookData = new bytes(0);

        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolKey.toId());

        int24 currentTick = TickMath.getTickAtSqrtPrice(sqrtPriceX96);

        int24 lower = currentTick - 100 * tickSpacing;
        int24 upper = currentTick + 100 * tickSpacing;

        // Clamp to Uniswap bounds
        if (lower < MIN_TICK) {
            lower = MIN_TICK;
        }
        if (upper > MAX_TICK) {
            upper = MAX_TICK;
        }

        // Truncate to spacing
        tickLower = truncateTickSpacing(MIN_TICK, tickSpacing);
        tickUpper = truncateTickSpacing(MAX_TICK, tickSpacing);

        // Converts token amounts to liquidity units
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            token0Amount,
            token1Amount
        );

        // slippage limits
        uint256 amount0Max = token0Amount + 1 wei;
        uint256 amount1Max = token1Amount + 1 wei;

        (bytes memory actions, bytes[] memory mintParams) = _mintLiquidityParams(
            poolKey, tickLower, tickUpper, liquidity, amount0Max, amount1Max, deployerAddress, hookData
        );

        // multicall parameters
        bytes[] memory params = new bytes[](1);
        require(liquidity > 0, "Computed liquidity is zero");
        // Mint Liquidity
        params[0] = abi.encodeWithSelector(
            positionManager.modifyLiquidities.selector, abi.encode(actions, mintParams), block.timestamp + 60
        );

        // If the pool is an ETH pair, native tokens are to be transferred
        uint256 valueToPass = currency0.isAddressZero() ? amount0Max : 0;

        vm.startBroadcast();
        tokenApprovals();

        // Add liquidity to existing pool
        positionManager.multicall{value: valueToPass}(params);
        vm.stopBroadcast();
    }
}
