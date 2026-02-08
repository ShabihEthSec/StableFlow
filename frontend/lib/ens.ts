// lib/ens.ts
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider(
  process.env.NEXT_PUBLIC_ETH_RPC!
);

export async function resolveENS(name: string) {
  const resolver = await provider.getResolver(name);
  if (!resolver) return null;

  return {
    status: await resolver.getText("stableflow:status"),
    mode: await resolver.getText("stableflow:mode"),
    execution: await resolver.getText("stableflow:execution"),
    hook: await resolver.getText("stableflow:hook"),
    executor: await resolver.getText("stableflow:executor"),
    threshold: await resolver.getText("stableflow:threshold:bps"),
  };
}
