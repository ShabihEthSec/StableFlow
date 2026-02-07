// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../../src/execution/RebalanceExecutionRegistry.sol";

contract RebalanceExecutionRegistryTest is Test {
    RebalanceExecutionRegistry registry;

    bytes32 internal poolId = keccak256("POOL_ID");
    int256 internal imbalanceBps = 750; // 7.5%
    bytes32 internal intentId;

    address internal executor = address(0xBEEF);

    function setUp() public {
        registry = new RebalanceExecutionRegistry();

        // Deterministic intentId for testing
        intentId = keccak256(
            abi.encode(poolId, imbalanceBps, uint256(1))
        );
    }

    /*//////////////////////////////////////////////////////////////
                            BASIC EXECUTION
    //////////////////////////////////////////////////////////////*/

    function test_markExecuted_setsExecutionState() public {
        vm.prank(executor);

        registry.markExecuted(intentId, poolId, imbalanceBps);

        (address recordedExecutor, uint64 executedAt) =
            registry.executions(intentId);

        assertEq(recordedExecutor, executor);
        assertGt(executedAt, 0);
        assertTrue(registry.isExecuted(intentId));
    }

    /*//////////////////////////////////////////////////////////////
                        EVENT EMISSION
    //////////////////////////////////////////////////////////////*/

    function test_markExecuted_emitsEvent() public {
        vm.prank(executor);

        vm.expectEmit(true, true, true, true);
        emit RebalanceExecutionRegistry.RebalanceExecuted(
            intentId,
            poolId,
            imbalanceBps,
            executor,
            block.timestamp
        );

        registry.markExecuted(intentId, poolId, imbalanceBps);
    }

    /*//////////////////////////////////////////////////////////////
                        REPLAY PROTECTION
    //////////////////////////////////////////////////////////////*/

    function test_revertOnDuplicateExecution() public {
        vm.prank(executor);
        registry.markExecuted(intentId, poolId, imbalanceBps);

        vm.prank(executor);
        vm.expectRevert("Intent already executed");
        registry.markExecuted(intentId, poolId, imbalanceBps);
    }

    /*//////////////////////////////////////////////////////////////
                    PERMISSIONLESS EXECUTION
    //////////////////////////////////////////////////////////////*/

    function test_anyAddressCanExecute() public {
        address randomExecutor = address(0xCAFE);

        vm.prank(randomExecutor);
        registry.markExecuted(intentId, poolId, imbalanceBps);

        (address recordedExecutor, ) =
            registry.executions(intentId);

        assertEq(recordedExecutor, randomExecutor);
    }
}
