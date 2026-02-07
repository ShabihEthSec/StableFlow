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

/// @title StableFlowHook
/// @author Mohd Shabihul Hasan Khan (ShabihEthSec)
/// @notice Uniswap v4 hook that observes swap flow to detect liquidity imbalance,
///         dynamically adjusts swap fees, and emits bounded rebalancing intents.
/// @dev This hook NEVER executes external calls or moves funds.
///      It only emits events to be handled asynchronously off-chain.



contract StableFlowHook is BaseHook {

    using PoolIdLibrary for PoolKey;
    using BalanceDeltaLibrary for BalanceDelta;

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    
    /// @notice Minimum imbalance (in basis points) required to emit a rebalancing intent.
    /// @dev Lowered for testnet/demo conditions. Mainnet would use a higher value.
    uint256 public constant IMBALANCE_THRESHOLD_BPS = 10; // 0.1%

     /// @notice Minimum time that must elapse between successive intents per pool.
    /// @dev Prevents intent spam and oscillation. Mainnet could use a longer cooldown.
    uint256 public constant REBALANCE_COOLDOWN = 2 minutes;

    /// @notice Fee applied when the pool is considered imbalanced.
    /// @dev Expressed in hundredths of a bip (Uniswap v4 format).
    uint24 public constant IMBALANCED_FEE = 3000; // 0.30%

    /// @notice Hard cap on reported imbalance to bound emitted values.
    uint256 public constant MAX_IMBALANCE_BPS = 2000; 

    /// @notice Flow aggregation window (5 minutes)
    uint256 public constant FLOW_WINDOW = 5 minutes;

    /// @notice Demo-only flag to force intent emission for deterministic demos.
    /// @dev MUST be disabled in production deployments.
    bool public DEMO_FORCE_INTENT = false;


    

    /*//////////////////////////////////////////////////////////////
                            EVENTS 
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when sustained swap flow indicates a liquidity imbalance.
    /// @param poolId The unique identifier of the affected pool.
    /// @param imbalanceBps The capped imbalance measurement (basis points).
    event RebalanceIntent(PoolId indexed poolId, uint256 imbalanceBps);

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp of the last emitted rebalance intent per pool.
    mapping(PoolId => uint256) public lastRebalanceAt;

    /// @notice Net aggregated swap flow within the active flow window.
    mapping(PoolId => int256) public cumulativeFlow;

    /// @notice Timestamp of the most recent flow update per pool.
    mapping(PoolId => uint256) public lastFlowUpdate;

    /// @notice Most recently computed imbalance per pool.
    mapping(PoolId => uint256) public lastImbalanceBps;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Initializes the hook with the Uniswap v4 PoolManager.
    /// @param _poolManager The canonical v4 PoolManager address.
    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    /*//////////////////////////////////////////////////////////////
                        HOOK PERMISSIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Declares which Uniswap v4 hook callbacks are enabled.
    /// @dev Only swap-related hooks are enabled. All others are disabled
    ///      to minimize surface area and gas usage.
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

    /// @notice Adjusts swap fees when a pool is flagged as imbalanced.
    /// @dev Uses previously computed imbalance state.
    ///      No state is mutated in this hook.
    /// @param key The pool key identifying the pool being swapped.
    /// @return selector The function selector for Uniswap v4.
    /// @return delta Always zero (no balance adjustments).
    /// @return fee The dynamically selected swap fee.
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
        
         uint24 fee = key.fee;

            
        // Apply higher fee if pool is currently imbalanced
        if (lastImbalanceBps[poolId] >= IMBALANCE_THRESHOLD_BPS) {
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

     /// @notice Aggregates swap flow, computes imbalance, and emits intent if thresholds are crossed.
    /// @dev This function:
    ///      - Observes BalanceDelta only
    ///      - Aggregates net flow over time
    ///      - Applies caps, thresholds, and cooldowns
    ///      - Emits an intent event without executing any external logic
    /// @param key The pool key identifying the pool being swapped.
    /// @param delta Net token balance changes from the swap.
    /// @return selector The function selector for Uniswap v4.
    /// @return hookDelta Always zero (no balance adjustments).
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

        // 🔴 DEMO MODE — deterministic intent emission
        if (DEMO_FORCE_INTENT) {
            lastRebalanceAt[poolId] = block.timestamp;
            lastImbalanceBps[poolId] = IMBALANCE_THRESHOLD_BPS;
            emit RebalanceIntent(poolId, IMBALANCE_THRESHOLD_BPS);
            return (BaseHook.afterSwap.selector, 0);
        }

        // Determine absolute swap pressure (one side will be negative)
        int128 amount0 = delta.amount0();
        int128 amount1 = delta.amount1();

        // One side is always negative (token paid in).
        // Track absolute flow of the sold token.
        int256 flow = amount0 < 0
        ? -int256(amount0)   
        : -int256(amount1); 

        // Reset or accumulate flow depending on time window
        if (block.timestamp > lastFlowUpdate[poolId] + FLOW_WINDOW) {
            cumulativeFlow[poolId] = flow;
        } else {
            cumulativeFlow[poolId] += flow;
        }

        lastFlowUpdate[poolId] = block.timestamp;


        // compute absolute flow
        uint256 absFlow = cumulativeFlow[poolId] >= 0
            ? uint256(cumulativeFlow[poolId])
            : uint256(-cumulativeFlow[poolId]);

        // Convert to basis points
        uint256 imbalanceBps = (absFlow * 10_000) / 1e18;

        // Cap imbalance to bound values
        if (imbalanceBps > MAX_IMBALANCE_BPS) {
            imbalanceBps = MAX_IMBALANCE_BPS;
        }

        // Ignore insignificant imbalance
        if (imbalanceBps < IMBALANCE_THRESHOLD_BPS) {
            return (BaseHook.afterSwap.selector, 0);
        }

        // Enforce cooldown
        if (
            lastRebalanceAt[poolId] != 0 &&
            block.timestamp <
                lastRebalanceAt[poolId] + REBALANCE_COOLDOWN
            ) {
            return (BaseHook.afterSwap.selector, 0);
        }

        lastImbalanceBps[poolId] = imbalanceBps;

        // Emit intent
        lastRebalanceAt[poolId] = block.timestamp;
        emit RebalanceIntent(poolId, imbalanceBps);

        // Reset flow to prevent chained emissions
        cumulativeFlow[poolId] = 0;

        return (BaseHook.afterSwap.selector, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        DEMO CONTROL
    //////////////////////////////////////////////////////////////*/

    /// @notice Enable or disable demo intent emission
    /// @dev ONLY for demos — remove for production
    function setDemoForceIntent(bool enabled) external {
        DEMO_FORCE_INTENT = enabled;
    }

}       


    
