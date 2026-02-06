import { ethers } from "ethers";
import { handleIntent } from "./executorLogic";
import * as dotenv from "dotenv";

dotenv.config();
// Executor policy (bps)
const THRESHOLD = BigInt(10); // 0.10% imbalance
console.log("Executor file loaded");

const ABI = [
  "event RebalanceIntent(bytes32 indexed poolId, uint256 imbalanceBps)"
];

async function main(): Promise<void> {
  const rpcUrl  = process.env.RPC_URL;
  const wsUrl   = process.env.WS_RPC_URL;
  const hookAddress = process.env.HOOK_ADDRESS;

  if (!rpcUrl || !wsUrl || !hookAddress) {
    throw new Error("Missing RPC_URL, WS_RPC_URL, or HOOK_ADDRESS");
  }
  
  // Providers
  const httpProvider = new ethers.JsonRpcProvider(rpcUrl);
  const wsProvider   = new ethers.WebSocketProvider(wsUrl);

  

  

  // Contracts
  const hookHttp = new ethers.Contract(hookAddress, ABI, httpProvider);
  const hookWs   = new ethers.Contract(hookAddress, ABI, wsProvider);

  console.log("🟢 StableFlow Executor running");

  /* ---------------------------------
     1️⃣ SAFE BACKFILL (≤ 10 blocks)
  ---------------------------------- */

  const latestBlock = await httpProvider.getBlockNumber();
  const fromBlock = Math.max(latestBlock - 5, 0);

  const pastEvents = await hookHttp.queryFilter(
    hookHttp.filters.RebalanceIntent(),
    fromBlock,
    latestBlock
  );

  for (const e of pastEvents) {
     if (e instanceof ethers.EventLog) {
      console.log("📜 Past RebalanceIntent");
      console.log("Pool ID:", e.args.poolId);
      console.log("Imbalance:", e.args.imbalanceBps.toString());
      console.log("Tx:", e.transactionHash);
      console.log("Block:", e.blockNumber);
      console.log("----------------------------------");
  
    }
  }
  /* ---------------------------------
     2️⃣ LIVE LISTENING (WebSocket)
  ---------------------------------- */

  console.log("Listening for RebalanceIntent...\n");

  hookWs.on("RebalanceIntent", async (poolId, imbalanceBps, log) => {
     try {
      // Optional threshold guard (keep for testing clarity)
      if (imbalanceBps < THRESHOLD) return;

      const receipt = await log.getTransactionReceipt();

      console.log("🔔 Rebalance Intent Detected");
      console.log("Pool ID:", poolId);
      console.log("Imbalance (bps):", imbalanceBps.toString());
      console.log("Tx:", receipt.transactionHash);
      console.log("Block:", receipt.blockNumber);
      console.log("----------------------------------");

      
      await handleIntent(
        {
          poolId,
          imbalanceBps,
          txHash: receipt.transactionHash,
          blockNumber: receipt.blockNumber,
        },
        httpProvider
      );

    } catch (err) {
      console.error("Executor error handling intent:", err);
    }
  });
}

main().catch((error) => {
  console.error("Executor crashed:", error);
  process.exit(1);
});
