// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title RebalanceExecutionRegistry
/// @notice Defines execution finality for StableFlow intents
/// @dev Does NOT move funds. Execution = on-chain acknowledgment only.
contract RebalanceExecutionRegistry {
    struct Execution {
        address executor;
        uint64 executedAt;
    }

    /// @notice intentId => execution record
    mapping(bytes32 => Execution) public executions;

    event RebalanceExecuted(
        bytes32 indexed intentId,
        bytes32 indexed poolId,
        int256 imbalanceBps,
        address indexed executor,
        uint256 timestamp
    );

    /// @notice Finalizes execution of a rebalance intent
    /// @dev Permissionless, replay-safe
    function markExecuted(
        bytes32 intentId,
        bytes32 poolId,
        int256 imbalanceBps
    ) external {
        require(
            executions[intentId].executedAt == 0,
            "Intent already executed"
        );

        executions[intentId] = Execution({
            executor: msg.sender,
            executedAt: uint64(block.timestamp)
        });

        emit RebalanceExecuted(
            intentId,
            poolId,
            imbalanceBps,
            msg.sender,
            block.timestamp
        );
    }

    function isExecuted(bytes32 intentId) external view returns (bool) {
        return executions[intentId].executedAt != 0;
    }
}
