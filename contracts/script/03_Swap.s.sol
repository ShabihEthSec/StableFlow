// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/console2.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

import {BaseScript} from "./base/BaseScript.sol";

contract SwapScript is BaseScript {
    using PoolIdLibrary for PoolKey;

    function run() external {
        PoolKey memory poolKey = PoolKey({
            currency0: currency0, // ETH
            currency1: currency1, // USDC
            fee: 500,
            tickSpacing: 60,
            hooks: hookContract
        });

        // 🔍 Compute and log PoolId
        PoolId id = poolKey.toId();
        console2.log("=== SWAP SCRIPT POOL ID ===");
        console2.logBytes32(PoolId.unwrap(id));

        bytes memory hookData = "";

        uint256 ethAmountIn = 1e13; // 0.0001 ETH
        uint256 usdcAmountIn = 1e6; // 1 USDC

        vm.startBroadcast();
        token1.approve(address(swapRouter), type(uint256).max);
        swapRouter.swapExactTokensForTokens({
            amountIn: usdcAmountIn,
            amountOutMin: 0,
            zeroForOne: false, // ETH -> USDC
            poolKey: poolKey,
            hookData: hookData,
            receiver: deployerAddress,
            deadline: block.timestamp + 120
        });

        vm.stopBroadcast();
    }
}
