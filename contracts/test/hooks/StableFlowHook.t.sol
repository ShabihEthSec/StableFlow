// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";

import {IPoolManager, SwapParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {HookMiner} from "lib/uniswap-hooks/lib/v4-periphery/src/utils/HookMiner.sol";
import {StableFlowHook, Hooks} from "src/hooks/StableFlowHook.sol";

/// @notice Test-only harness to expose internal hook functions
contract StableFlowHookHarness is StableFlowHook {
    constructor(IPoolManager manager) StableFlowHook(manager) {}

    function callAfterSwap(PoolKey calldata key, SwapParams calldata params, bytes calldata hookdata) external {
        _afterSwap(
            address(0),
            key,
            params,
            BalanceDelta.wrap(0),
            hookdata
        );
    }
}
                
contract StableFlowHookTest is Test {
    StableFlowHookHarness hook;

    function setUp() public {
        // We do NOT need a real PoolManager for Phase 1
        IPoolManager dummyManager = IPoolManager(address(0x1234));
        uint160 flags = Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG;

        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(StableFlowHookHarness).creationCode,
            abi.encode(dummyManager)
        );
        hook = new StableFlowHookHarness{salt: salt}(dummyManager);
        
    }

    function test_getHookPermissions() public {
        Hooks.Permissions memory perms = hook.getHookPermissions();

        assertTrue(perms.beforeSwap, "beforeSwap should be enabled");
        assertTrue(perms.afterSwap, "afterSwap should be enabled");

        assertFalse(perms.beforeAddLiquidity, "beforeAddLiquidity should be disabled");
        assertFalse(perms.afterAddLiquidity, "afterAddLiquidity should be disabled");
    }

    function test_afterSwap_emitsRebalanceIntent() public {
        PoolKey memory key;

        vm.expectEmit(true, false, false, true);
        emit StableFlowHook.RebalanceIntent(key.toId(), 500);

        hook.callAfterSwap(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: 1000,
                sqrtPriceLimitX96: 0
            }),
            new bytes(0)
        );
    }
}
