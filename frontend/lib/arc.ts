// lib/arc.ts
import { ethers } from "ethers";

export const arcProvider = new ethers.JsonRpcProvider(
  process.env.NEXT_PUBLIC_ARC_RPC!,
  {
    chainId: 5042002,
    name: "arc-testnet",
    ensAddress: undefined,
  }
);

export async function getUSDCBalance(address: string) {
  const balance = await arcProvider.getBalance(address);
  return Number(ethers.formatUnits(balance, 18)); // USDC (Arc native token) = 18 decimals
}
