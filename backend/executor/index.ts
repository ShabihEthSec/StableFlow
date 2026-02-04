import { ethers } from "ethers";
import * as dotenv from "dotenv";

dotenv.config();

console.log("Executor file loaded");

const ABI: string[] = [
  "event RebalanceIntent(bytes32 indexed poolId, uint256 imbalanceBps)"
];

async function main(): Promise<void> {
  const rpcUrl = process.env.RPC_URL;
  const hookAddress = process.env.HOOK_ADDRESS;

  if (!rpcUrl || !hookAddress) {
    throw new Error("Missing RPC_URL or HOOK_ADDRESS in environment variables");
  }

  const provider = new ethers.JsonRpcProvider(rpcUrl);

  const hook = new ethers.Contract(
    hookAddress,
    ABI,
    provider
  );

  console.log("🟢 StableFlow Executor running");
  console.log("Listening for RebalanceIntent...\n");

  hook.on(
    "RebalanceIntent",
    (
      poolId: string,
      imbalanceBps: bigint,
      event: ethers.EventLog
    ) => {
      console.log("🔔 Rebalance Intent Detected");
      console.log("Pool ID:", poolId);
      console.log("Imbalance (bps):", imbalanceBps.toString());
      console.log("Tx:", event.transactionHash);
      console.log("Block:", event.blockNumber);
      console.log("----------------------------------");
    }
  );
}

main().catch((error) => {
  console.error("Executor crashed:", error);
  process.exit(1);
});
