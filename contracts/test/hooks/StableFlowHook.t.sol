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
    // using SafeCast for int128;
    // using SafeCast for uint128;
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

    function test_getHookPermissions() public {
        Hooks.Permissions memory perms = hook.getHookPermissions();

        assertTrue(perms.beforeSwap, "beforeSwap should be enabled");
        assertTrue(perms.afterSwap, "afterSwap should be enabled");

        assertFalse(perms.beforeAddLiquidity, "beforeAddLiquidity should be disabled");
        assertFalse(perms.afterAddLiquidity, "afterAddLiquidity should be disabled");
    }

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
        BalanceDelta largeDelta = toBalanceDelta(
            int128(-1e18),
            int128(1e18)
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

    /// Cooldown prevents spam
    function test_afterSwap_cooldownBlocksSecondIntent() public {
        BalanceDelta largeDelta = toBalanceDelta(
            int128(-1e18),
            int128(1e18)
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
        Vm.Log[] memory logs1 = vm.getRecordedLogs();
        uint256 count1;
        for (uint256 i = 0; i < logs1.length; i++) {
            if (
                logs1[i].topics[0]
                    == keccak256("RebalanceIntent(bytes32,uint256)")
            ) {
                count1++;
            }
        }
        assertEq(count1, 1, "first intent should emit");

        // ---- Second swap: SHOULD NOT emit  ----
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

        Vm.Log[] memory logs2 = vm.getRecordedLogs();
        uint256 count2;

        for (uint256 i = 0; i < logs2.length; i++) {
            if (
                logs2[i].topics[0]
                    == keccak256("RebalanceIntent(bytes32,uint256)")
            ) {
                count2++;
            }
        }

        assertEq(count2, 0, "cooldown should block second intent");
    }

    /// Fee increases after imbalance
    function test_beforeSwap_appliesDynamicFee() public {
         BalanceDelta largeDelta = toBalanceDelta(
            int128(-1e16),
            int128(1e16)
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


    // function test_afterSwap_emitsRebalanceIntent() public {
    //     PoolKey memory key;

    //     vm.expectEmit(true, false, false, true);
    //     emit StableFlowHook.RebalanceIntent(key.toId(), 500);

    //     hook.callAfterSwap(
    //         key,
    //         SwapParams({
    //             zeroForOne: true,
    //             amountSpecified: 1000,
    //             sqrtPriceLimitX96: 0
    //         }),
    //         new bytes(0)
    //     );
    // }

    // -------------------------------- HELPER FUNCTIONS --------------------------------
    function _makeDelta(int128 amount0, int128 amount1)
        internal
        pure
        returns (BalanceDelta)
    {
        return BalanceDelta.wrap(
            (int256(amount0) << 128) | int256(uint256(uint128(amount1)))
        );
    }
}
