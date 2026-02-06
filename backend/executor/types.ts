// backend/executor/types.ts

export interface RebalanceIntent {
  poolId: string;
  imbalanceBps: bigint;
  txHash?: string;
  blockNumber?: number;
}


