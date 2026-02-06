import "dotenv/config";
import { RebalanceIntent } from "./types";
import { resolveProtocolConfig } from "./ens";
import { ethers } from "ethers";

export async function handleIntent(
  intent: RebalanceIntent,
  provider: ethers.AbstractProvider
) {
  console.log("🧠 Evaluating intent");

  if (!process.env.RPC_URL) {
    throw new Error("Missing SEPOLIA_RPC_URL");
  }
  
  if (!process.env.PROTOCOL_ENS_NAME) {
    throw new Error("Missing PROTOCOL_ENS_NAME");
  }

  const ensProvider = new ethers.JsonRpcProvider(process.env.RPC_URL);


  const ENS_NAME = process.env.PROTOCOL_ENS_NAME!;

  const config = await resolveProtocolConfig(ensProvider, ENS_NAME);

  console.log("📜 Protocol config (ENS)", config);

  if (config.status !== "active") {
    console.log("⏸ Protocol paused via ENS");
    return;
  }

  

  if (intent.imbalanceBps < config.intentThresholdBps) {
    console.log("⏭ Below ENS threshold");
    return;
  }

  console.log("✅ Intent accepted (ENS-governed)");
}
