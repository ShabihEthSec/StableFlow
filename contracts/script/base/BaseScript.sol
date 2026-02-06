// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {IUniswapV4Router04} from "hookmate/interfaces/router/IUniswapV4Router04.sol";
import {AddressConstants} from "hookmate/constants/AddressConstants.sol";

import {Deployers} from "test/utils/Deployers.sol";

/// @notice Shared configuration between scripts (Native ETH / USDC)
contract BaseScript is Script, Deployers {
    using CurrencyLibrary for Currency;

    address immutable deployerAddress;

    /////////////////////////////////////
    // --- Configure These ---
    /////////////////////////////////////

    /// USDC Sepolia
    address internal constant USDC_ADDR =
        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;

    IHooks constant hookContract =
        IHooks(0x6cbc5627c02c69302C2453aD8b7Fb29FD91680C0);

    /////////////////////////////////////

    /// Sorted currencies (ETH / USDC)
    Currency immutable currency0;
    Currency immutable currency1;

    /// ERC20 handles (ONLY valid if currency is not ETH)
    IERC20 internal immutable token0;
    IERC20 internal immutable token1;

    constructor() {
        // Make sure artifacts are available, either deploy or configure.
        deployArtifacts();

        deployerAddress = getDeployer();

        (currency0, currency1) = getCurrencies();

        // Derive ERC20 handles safely
        token0 = currency0.isAddressZero()
            ? IERC20(address(0))
            : IERC20(Currency.unwrap(currency0));

        token1 = currency1.isAddressZero()
            ? IERC20(address(0))
            : IERC20(Currency.unwrap(currency1));

        vm.label(address(permit2), "Permit2");
        vm.label(address(poolManager), "V4PoolManager");
        vm.label(address(positionManager), "V4PositionManager");
        vm.label(address(swapRouter), "V4SwapRouter");

        if (currency0.isAddressZero()) {
            vm.label(address(0), "Currency0 (ETH)");
        } else {
            vm.label(address(token0), "Currency0 (ERC20)");
        }

        if (currency1.isAddressZero()) {
            vm.label(address(0), "Currency1 (ETH)");
        } else {
            vm.label(address(token1), "Currency1 (ERC20)");
        }

        vm.label(address(hookContract), "HookContract");
    }

    function _etch(address target, bytes memory bytecode) internal override {
        if (block.chainid == 31337) {
            vm.rpc(
                "anvil_setCode",
                string.concat(
                    '["',
                    vm.toString(target),
                    '","',
                    vm.toString(bytecode),
                    '"]'
                )
            );
        } else {
            revert("Unsupported etch on this network");
        }
    }

    /// @notice Returns sorted ETH / USDC currencies
    function getCurrencies() internal pure returns (Currency, Currency) {
        Currency eth  = Currency.wrap(address(0));
        Currency usdc = Currency.wrap(USDC_ADDR);

        if (eth < usdc) {
            return (eth, usdc);
        } else {
            return (usdc, eth);
        }
    }

    function getDeployer() internal returns (address) {
        address[] memory wallets = vm.getWallets();
        return wallets.length > 0 ? wallets[0] : msg.sender;
    }
}
