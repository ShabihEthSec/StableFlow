import { createPublicClient, http, parseAbi } from "viem";
import { mainnet } from "viem/chains";

export const ensClient = createPublicClient({
  chain: mainnet,
  transport: http(),
});

export async function resolveENS(name: string) {
  return ensClient.getEnsAddress({ name });
}
