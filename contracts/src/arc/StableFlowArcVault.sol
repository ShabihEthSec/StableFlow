// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Minimal ERC20 interface for USDC on Arc
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title StableFlowArcVault
/// @author Mohd Shabihul Hasan Khan (ShabihEthSec)
/// @notice Canonical USDC liquidity hub for StableFlow on Arc
/// @dev Settlement-only. No users, no shares, no execution logic.
contract StableFlowArcVault {
    /// @notice Arc USDC token
    IERC20 public immutable usdc;

    /// @notice Executor allowed to settle rebalances
    address public immutable executor;

    /// @notice intentId => settled
    mapping(bytes32 => bool) public settled;

    /// @notice poolId => net USDC exposure
    mapping(bytes32 => int256) public poolExposure;

    event RebalanceSettled(
        bytes32 indexed intentId,
        bytes32 indexed poolId,
        int256 deltaUSDC,
        uint256 totalUSDC
    );

    constructor(address usdc_, address executor_) {
        require(usdc_ != address(0), "USDC_ZERO");
        require(executor_ != address(0), "EXECUTOR_ZERO");
        usdc = IERC20(usdc_);
        executor = executor_;
    }

    /// @notice Apply a rebalance after execution is finalized
    /// @dev Called by off-chain executor only
    function settleRebalance(
        bytes32 intentId,
        bytes32 poolId,
        int256 deltaUSDC
    ) external {
        require(msg.sender == executor, "NOT_EXECUTOR");
        require(!settled[intentId], "ALREADY_SETTLED");

        settled[intentId] = true;
        poolExposure[poolId] += deltaUSDC;

        emit RebalanceSettled(
            intentId,
            poolId,
            deltaUSDC,
            usdc.balanceOf(address(this))
        );
    }

    /// @notice Total USDC held by StableFlow on Arc
    function totalUSDC() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
}
