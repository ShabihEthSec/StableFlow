// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BalanceDeltaLibrary} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

contract StableFlowHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using BalanceDeltaLibrary for BalanceDelta;

    /// @notice emitted when pool imbalance crosses threshold
    event RebalanceIntent(PoolId indexed poolId, uint256 imbalanceBps);

    /// @notice Minimum imbalance to trigger rebalancing (5%)
    uint256 public constant IMBALANCE_THRESHOLD_BPS = 500;

    /// @notice Minimum time between rebalancing events (30 minutes)
    uint256 public constant REBALANCE_COOLDOWN = 30 minutes;

    /// @notice Dynamic fee when pool is imbalanced (0.30%)
    uint24 public constant IMBALANCED_FEE = 3000;

    /// @notice Track last rebalance timestamp per pool
    mapping(PoolId => uint256) public lastRebalanceAt;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    /*//////////////////////////////////////////////////////////////
                        HOOK PERMISSIONS
    //////////////////////////////////////////////////////////////*/

    
    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /*//////////////////////////////////////////////////////////////
                        BEFORE SWAP
    //////////////////////////////////////////////////////////////*/

    /// @notice Increase fees when recent imbalance was detected
    function _beforeSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata,
        bytes calldata
    )
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
         PoolId poolId = key.toId();
        
         uint24 fee = 0;

        // If pool recently triggered imbalance, apply higher fee
        if (
            block.timestamp <
            lastRebalanceAt[poolId] + REBALANCE_COOLDOWN
        ) {
            fee = IMBALANCED_FEE;
        }

        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            fee
        );
    }

     /*//////////////////////////////////////////////////////////////
                        AFTER SWAP
    //////////////////////////////////////////////////////////////*/

    /// @notice Detect imbalance and emit intent
    function _afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    )
        internal
        override
        returns (bytes4, int128)
    {
        PoolId poolId = key.toId();

        // Determine absolute swap pressure (one side will be negative)
        int128 amount0 = delta.amount0();
        int128 amount1 = delta.amount1();

        uint256 absSwap = amount0 < 0
            ? uint256(int256(-amount0))
            : uint256(int256(-amount1));

        // Phase-2 heuristic: scale swap size to basis points
        // NOTE: simple, bounded, manipulation-resistant enough for Phase-2
        uint256 imbalanceBps = (absSwap * 10_000) / 1e18;

        // Threshold check
        if (imbalanceBps < IMBALANCE_THRESHOLD_BPS) {
            return (BaseHook.afterSwap.selector, 0);
        }

        // Cooldown check
        if (
            lastRebalanceAt[poolId] != 0 &&
            block.timestamp <
                lastRebalanceAt[poolId] + REBALANCE_COOLDOWN
            ) {
            return (BaseHook.afterSwap.selector, 0);
        }

        lastRebalanceAt[poolId] = block.timestamp;
        emit RebalanceIntent(poolId, imbalanceBps);

        return (BaseHook.afterSwap.selector, 0);
    }
}

    
