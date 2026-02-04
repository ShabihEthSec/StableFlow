// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";

import {IPoolManager, SwapParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta, toBalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {HookMiner} from "lib/uniswap-hooks/lib/v4-periphery/src/utils/HookMiner.sol";
import {StableFlowHook, Hooks} from "src/hooks/StableFlowHook.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";

/// @notice Test-only harness to expose internal hook functions
contract StableFlowHookHarness is StableFlowHook {
    constructor(IPoolManager manager) StableFlowHook(manager) {}

    function callAfterSwap(PoolKey calldata key, SwapParams calldata params, BalanceDelta delta, bytes calldata hookdata) external {
        _afterSwap(
            address(0),
            key,
            params,
            delta,
            hookdata
        );
    }
    function callBeforeSwap(
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookdata
        
    ) external returns (uint24 fee) {
        (, , fee) = _beforeSwap(
            address(0),
            key,
            params,
            hookdata
        );
    }
}
                
contract StableFlowHookTest is Test {
    using PoolIdLibrary for PoolKey;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencyLibrary for Currency;
    
    StableFlowHookHarness hook;

    PoolKey poolKey;

    function setUp() public {
        IPoolManager dummyManager = IPoolManager(address(0x1234));
        uint160 flags = Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG;

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(StableFlowHookHarness).creationCode,
            abi.encode(dummyManager)
        );
        hook = new StableFlowHookHarness{salt: salt}(dummyManager);

        poolKey = PoolKey({
            currency0: Currency.wrap(address(0x1)),
            currency1: Currency.wrap(address(0x2)),
            fee: 500,
            tickSpacing: 10,
            hooks: hook
        });
        
    }
    /*//////////////////////////////////////////////////////////////
                            TESTS
    //////////////////////////////////////////////////////////////*/

    function test_getHookPermissions() public {
        Hooks.Permissions memory perms = hook.getHookPermissions();

        assertTrue(perms.beforeSwap, "beforeSwap should be enabled");
        assertTrue(perms.afterSwap, "afterSwap should be enabled");

        assertFalse(perms.beforeAddLiquidity, "beforeAddLiquidity should be disabled");
        assertFalse(perms.afterAddLiquidity, "afterAddLiquidity should be disabled");
    }

    /// Small swap → no intent emitted
    function test_afterSwap_noIntentBelowThreshold() public {
        BalanceDelta smallDelta = toBalanceDelta(
            int128(-1e16),
            int128(1e16)
        );

        vm.recordLogs();

        hook.callAfterSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1e16,
                sqrtPriceLimitX96: 0
            }),
            smallDelta,
            bytes("")
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0);
    }

    /// Large swap → intent emitted
    function test_afterSwap_emitsIntentAboveThreshold() public {
        BalanceDelta largeDelta = BalanceDelta.wrap(
            (int256(-1e18) << 128) | int256(uint256(uint128(1e18)))
        );

        vm.recordLogs();

        hook.callAfterSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1e18,
                sqrtPriceLimitX96: 0
            }),
            largeDelta,
            bytes("")
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool found;

        for (uint256 i = 0; i < logs.length; i++) {
            if (
                logs[i].topics[0]
                    == keccak256("RebalanceIntent(bytes32,uint256)")
            ) {
                found = true;
            }
        }

        assertTrue(found);
    }

    /// Cooldown blocks second intent
    function test_afterSwap_cooldownBlocksSecondIntent() public {
        BalanceDelta largeDelta = BalanceDelta.wrap(
            (int256(-1e18) << 128) | int256(uint256(uint128(1e18)))
        );

        // ---- First swap: Should emit ----
        vm.recordLogs();

        hook.callAfterSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1e18,
                sqrtPriceLimitX96: 0
            }),
            largeDelta,
            bytes("")
        );

         // Second swap in same block → blocked
        hook.callAfterSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1e18,
                sqrtPriceLimitX96: 0
            }),
            largeDelta,
            bytes("")
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 count;

        for (uint256 i = 0; i < logs.length; i++) {
            if (
                logs[i].topics[0]
                    == keccak256("RebalanceIntent(bytes32,uint256)")
            ) {
                count++;
            }
        }

        assertEq(count, 1);
    }

    /// Fee increases after imbalance
    function test_beforeSwap_appliesDynamicFee() public {
         BalanceDelta largeDelta = BalanceDelta.wrap(
            (int256(-1e18) << 128) | int256(uint256(uint128(1e18)))
        );

        hook.callAfterSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1e18,
                sqrtPriceLimitX96: 0
            }),
            largeDelta,
            bytes("")
        );

        uint24 fee = hook.callBeforeSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -1e6,
                sqrtPriceLimitX96: 0
            }),
            bytes("")
        );

        assertEq(fee, hook.IMBALANCED_FEE());
    }    

    function test_flowAccumulatesAcrossSwaps() public {
        BalanceDelta delta = toBalanceDelta(
            int128(-3e17),
            int128(3e17)
        );

        hook.callAfterSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -3e17,
                sqrtPriceLimitX96: 0
            }),
            delta,
            bytes("")
        );
        hook.callAfterSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -3e17,
                sqrtPriceLimitX96: 0
            }),
            delta,
            bytes("")
        );

        uint256 imbalance = hook.lastImbalanceBps(poolKey.toId());
        assertGt(imbalance, hook.IMBALANCE_THRESHOLD_BPS());
    }
}
