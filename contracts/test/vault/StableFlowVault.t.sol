// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {StableFlowVault} from "src/vault/StableFlowVault.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract StableFlowVaultTest is Test {
    StableFlowVault vault;
    MockUSDC usdc;

    function setUp() public {
        usdc = new MockUSDC();
        vault = new StableFlowVault(usdc);
    }

    function test_deposit_mintsShares() public {
        uint256 amount = 1_000e6;

        usdc.mint(address(this), amount);
        usdc.approve(address(vault), amount);

        uint256 shares = vault.deposit(amount, address(this));

        assertEq(shares, amount);
        assertEq(vault.balanceOf(address(this)), amount);
        assertEq(usdc.balanceOf(address(vault)), amount);
    }

    function test_withdraw_returnsAssets() public {
        uint256 amount = 1_000e6;

        usdc.mint(address(this), amount);
        usdc.approve(address(vault), amount);
        vault.deposit(amount, address(this));

        uint256 assets = vault.withdraw(
            amount,
            address(this),
            address(this)
        );

        assertEq(assets, amount);
        assertEq(usdc.balanceOf(address(this)), amount);
        assertEq(vault.balanceOf(address(this)), 0);
    }

    function test_totalAssets_matchesBalance() public {
        uint256 amount = 500e6;

        usdc.mint(address(this), amount);
        usdc.approve(address(vault), amount);
        vault.deposit(amount, address(this));

        assertEq(vault.totalAssets(), amount);
    }


}