// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BaseScript} from "./base/BaseScript.sol";

contract SwapScript is BaseScript {
    function run() external {
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: hookContract
        });

        bytes memory hookData = "";

        vm.startBroadcast();

        // Approve ONLY the input token
        token1.approve(address(swapRouter), type(uint256).max);

        // Small swap — enough to trigger flow logic safely
        swapRouter.swapExactTokensForTokens({
            amountIn: 1e6,        //  1 USDC (6 decimals)
            amountOutMin: 0,
            zeroForOne: true,
            poolKey: poolKey,
            hookData: hookData,
            receiver: msg.sender, //  my wallet
            deadline: block.timestamp + 120
        });

        vm.stopBroadcast();
    }
}
