
import { ethers } from "ethers";

export async function resolveProtocolConfig(
  provider: ethers.AbstractProvider,   
  ensName: string
) {
  const resolver = await provider.getResolver(ensName);

  if (!resolver) {
    const network = await provider.getNetwork();
    throw new Error(
      `ENS resolver not found for ${ensName} on chain ${network.chainId}`
    );
  }

  const hook = await resolver.getText("stableflow:hook");
  const threshold = await resolver.getText("stableflow:threshold:bps");
  const status = await resolver.getText("stableflow:status");
  const executor = await resolver.getText("executor");
  const mode = await resolver.getText("stableflow:mode");
  const chain = await resolver.getText("stableflow:chain");

  return {
    hook,
    intentThresholdBps: BigInt(threshold || "0"),
    status: status || "inactive",
    executor: executor || "unknown",
    mode: mode || "unknown",
    chain: chain || "unknown",
  };
}
