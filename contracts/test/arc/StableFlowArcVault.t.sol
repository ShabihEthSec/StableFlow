// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../../src/arc/StableFlowArcVault.sol";

/*//////////////////////////////////////////////////////////////
                            MOCK USDC
//////////////////////////////////////////////////////////////*/

contract MockUSDC is IERC20 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(balanceOf[from] >= amount, "INSUFFICIENT");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

/*//////////////////////////////////////////////////////////////
                        TEST CONTRACT
//////////////////////////////////////////////////////////////*/

contract StableFlowArcVaultTest is Test {
    StableFlowArcVault internal vault;
    MockUSDC internal usdc;

    address internal executor = address(0xBEEF);
    address internal attacker = address(0xCAFE);

    bytes32 internal poolId = keccak256("POOL_A");
    bytes32 internal intentId = keccak256("INTENT_1");

    function setUp() public {
        usdc = new MockUSDC();
        vault = new StableFlowArcVault(address(usdc), executor);

        // Seed vault with USDC
        usdc.mint(address(vault), 1_000_000e6);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function test_constructor_setsState() public view {
        assertEq(address(vault.usdc()), address(usdc));
        assertEq(vault.executor(), executor);
    }

    function test_constructor_revertOnZeroUSDC() public {
        vm.expectRevert("USDC_ZERO");
        new StableFlowArcVault(address(0), executor);
    }

    function test_constructor_revertOnZeroExecutor() public {
        vm.expectRevert("EXECUTOR_ZERO");
        new StableFlowArcVault(address(usdc), address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    function test_revertIfNotExecutor() public {
        vm.prank(attacker);
        vm.expectRevert("NOT_EXECUTOR");
        vault.settleRebalance(intentId, poolId, 100e6);
    }

    /*//////////////////////////////////////////////////////////////
                        SETTLEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function test_settleRebalance_setsState() public {
        vm.prank(executor);
        vault.settleRebalance(intentId, poolId, 250e6);

        assertTrue(vault.settled(intentId));
        assertEq(vault.poolExposure(poolId), 250e6);
    }

    function test_settleRebalance_negativeDelta() public {
        vm.prank(executor);
        vault.settleRebalance(intentId, poolId, -100e6);

        assertEq(vault.poolExposure(poolId), -100e6);
    }

    function test_settleRebalance_accumulatesExposure() public {
        vm.startPrank(executor);

        vault.settleRebalance(
            keccak256("INTENT_1"),
            poolId,
            300e6
        );

        vault.settleRebalance(
            keccak256("INTENT_2"),
            poolId,
            -50e6
        );

        vm.stopPrank();

        assertEq(vault.poolExposure(poolId), 250e6);
    }

    /*//////////////////////////////////////////////////////////////
                        REPLAY PROTECTION
    //////////////////////////////////////////////////////////////*/

    function test_revertOnDuplicateIntent() public {
        vm.prank(executor);
        vault.settleRebalance(intentId, poolId, 100e6);

        vm.prank(executor);
        vm.expectRevert("ALREADY_SETTLED");
        vault.settleRebalance(intentId, poolId, 50e6);
    }

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    function test_settleRebalance_emitsEvent() public {
        uint256 expectedBalance = usdc.balanceOf(address(vault));

        vm.prank(executor);

        vm.expectEmit(true, true, true, true);
        emit StableFlowArcVault.RebalanceSettled(
            intentId,
            poolId,
            100e6,
            expectedBalance
        );

        vault.settleRebalance(intentId, poolId, 100e6);
    }

    /*//////////////////////////////////////////////////////////////
                        TOTAL USDC VIEW
    //////////////////////////////////////////////////////////////*/

    function test_totalUSDC_matchesBalance() public view {
        assertEq(
            vault.totalUSDC(),
            usdc.balanceOf(address(vault))
        );
    }

    /*//////////////////////////////////////////////////////////////
                        STORAGE INVARIANTS
    //////////////////////////////////////////////////////////////*/

    function test_settlementImmutableAfterWrite() public {
        vm.prank(executor);
        vault.settleRebalance(intentId, poolId, 123e6);

        int256 exposureBefore = vault.poolExposure(poolId);

        vm.warp(block.timestamp + 1 days);

        assertTrue(vault.settled(intentId));
        assertEq(vault.poolExposure(poolId), exposureBefore);
    }
}
