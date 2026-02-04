// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @notice Phase 4 vault
 * - No liquidity deployment
 * - No Uniswap interaction
 * - No cross-chain logic
 * - No async execution
 * - Sole purpose: safe custody + share accounting
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract StableFlowVault is ERC4626 {
    constructor(
        ERC20 asset_
    )
        ERC20("StableFlow Vault Share", "sfUSDC")
        ERC4626(asset_)
    {}
}
