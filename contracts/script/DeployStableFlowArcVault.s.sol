// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "../src/arc/StableFlowArcVault.sol";

contract DeployStableFlowArcVault is Script {
    /// -----------------------------------------------------------------------
    /// 🔧 CONFIG — HARD-CODED FOR HACKATHON
    /// -----------------------------------------------------------------------

    
    address constant ARC_USDC = 0x3600000000000000000000000000000000000000;

    
    address constant EXECUTOR = 0x1f97130fFAC3D1edb06a17c0e7c6599aD027E5AB;
    function run() external {
        uint256 deployerKey = vm.envUint("EXECUTOR_PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        StableFlowArcVault vault = new StableFlowArcVault(
            ARC_USDC,
            EXECUTOR
        );

        vm.stopBroadcast();

        console.log("StableFlowArcVault deployed at:");
        console.logAddress(address(vault));
    }
}
