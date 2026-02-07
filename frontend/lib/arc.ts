import { createPublicClient, http } from "viem";
import { CONFIG } from "../config";

export const arcClient = createPublicClient({
  transport: http(CONFIG.ARC.rpc),
});

export const ARC_VAULT_ABI = [
  {
    name: "totalUSDC",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "uint256" }],
  },
];
