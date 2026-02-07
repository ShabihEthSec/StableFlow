import "dotenv/config";
import { RebalanceIntent } from "./types";
import { resolveProtocolConfig } from "./ens";
import { ethers } from "ethers";

const EXECUTION_REGISTRY_ABI = [
  "function markExecuted(bytes32 intentId, bytes32 poolId, int256 imbalanceBps) external"
];

const ARC_VAULT_ABI = [
  "function settleRebalance(bytes32 intentId, bytes32 poolId, int256 deltaUSDC) external"
];

export async function handleIntent(
  intent: RebalanceIntent,
  _provider: ethers.AbstractProvider
) {
  console.log("🔥 NEW EXECUTOR VERSION — ARC ENABLED 🔥");
  console.log("🧠 Evaluating intent");

  // --------------------
  // ENV CHECKS
  // --------------------
  if (!process.env.RPC_URL) throw new Error("Missing SEPOLIA_RPC_URL");
  if (!process.env.ARC_RPC_URL) throw new Error("Missing ARC_RPC_URL");
  if (!process.env.PROTOCOL_ENS_NAME) throw new Error("Missing PROTOCOL_ENS_NAME");
  if (!process.env.EXECUTOR_PRIVATE_KEY) throw new Error("Missing EXECUTOR_PRIVATE_KEY");
  if (!process.env.EXECUTION_REGISTRY_ADDRESS) throw new Error("Missing EXECUTION_REGISTRY_ADDRESS");
  if (!process.env.ARC_VAULT_ADDRESS) throw new Error("Missing ARC_VAULT_ADDRESS");

  // --------------------
  // PROVIDERS
  // --------------------
  const sepoliaProvider = new ethers.JsonRpcProvider(process.env.RPC_URL);
  const arcProvider = new ethers.JsonRpcProvider(process.env.ARC_RPC_URL);

  // --------------------
  // SIGNERS
  // --------------------
  const sepoliaSigner = new ethers.Wallet(
    process.env.EXECUTOR_PRIVATE_KEY,
    sepoliaProvider
  );

  const arcSigner = new ethers.Wallet(
    process.env.EXECUTOR_PRIVATE_KEY,
    arcProvider
  );

  // --------------------
  // ENS CONFIG
  // --------------------
  const ENS_NAME = process.env.PROTOCOL_ENS_NAME!;
  const config = await resolveProtocolConfig(sepoliaProvider, ENS_NAME);

  console.log("📜 Protocol config (ENS)", config);

  // --------------------
  // AUTH CHECK
  // --------------------
  if (
    config.executor &&
    config.executor !== "unknown" &&
    config.executor.toLowerCase() !== sepoliaSigner.address.toLowerCase()
  ) {
    console.log("🚫 Executor not authorized via ENS");
    return;
  }

  if (config.status !== "active") {
    console.log("⏸ Protocol paused via ENS");
    return;
  }

  if (config.execution !== "enabled") {
    console.log("⏸ Execution disabled via ENS");
    return;
  }

  if (intent.imbalanceBps < config.intentThresholdBps) {
    console.log("⏭ Below ENS threshold");
    return;
  }

  // --------------------
  // INTENT ID
  // --------------------
  const intentId = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "int256", "uint256"],
      [intent.poolId, intent.imbalanceBps, intent.blockNumber]
    )
  );

  console.log("🆔 intentId:", intentId);

  // --------------------
  // DEMO MODE
  // --------------------
  if (config.mode === "demo") {
    console.log("🟡 Demo mode — execution skipped");
    return;
  }

  // --------------------
  // LIVE MODE
  // --------------------
  console.log("🟢 Live mode — executing intent");

  // Simulated USDC delta (hackathon-safe)
  const deltaUSDC = BigInt(intent.imbalanceBps) * 1_000_000n;

  // --------------------
  // SEPOLIA: EXECUTION REGISTRY
  // --------------------
  const registry = new ethers.Contract(
    process.env.EXECUTION_REGISTRY_ADDRESS!,
    EXECUTION_REGISTRY_ABI,
    sepoliaSigner
  );

  try {
    const execTx = await registry.markExecuted(
      intentId,
      intent.poolId,
      intent.imbalanceBps
    );

    console.log("📤 ExecutionRegistry tx:", execTx.hash);
    await execTx.wait();
    console.log("✅ ExecutionRegistry finalized");

    // --------------------
    // ARC: SETTLEMENT
    // --------------------
    const arcVault = new ethers.Contract(
      process.env.ARC_VAULT_ADDRESS!,
      ARC_VAULT_ABI,
      arcSigner
    );

    console.log("🌉 Settling on Arc...");

    const arcTx = await arcVault.settleRebalance(
      intentId,
      intent.poolId,
      deltaUSDC
    );

    console.log("📤 Arc settlement tx:", arcTx.hash);
    await arcTx.wait();

    console.log("💰 Arc settlement finalized");

  } catch (err: any) {
    if (err?.reason?.includes("Intent already executed")) {
      console.log("⏭ Intent already executed, skipping");
      return;
    }
    throw err;
  }
}
