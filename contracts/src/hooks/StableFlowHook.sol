// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

contract StableFlowHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    /// @notice emitted when pool imbalance crosses threshold
    event RebalanceIntent(PoolId indexed poolId, uint256 imbalanceBps);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    /// @notice declare which hooks we use
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

    /// @notice adjust fees later (Phase 2)
    function _beforeSwap(
        address,
        PoolKey calldata,
        SwapParams calldata,
        bytes calldata
    )
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // Phase 1: no fee modification yet
        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            0
        );
    }

    /// @notice emit intent when imbalance detected
    function _afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    )
        internal
        override
        returns (bytes4, int128)
    {
        // Phase 1: hardcoded imbalance for plumbing test
        emit RebalanceIntent(key.toId(), 500); // 5.00%

        return (BaseHook.afterSwap.selector, 0);
    }
}
