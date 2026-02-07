"use client";

import { useEffect, useState } from "react";
import { arcClient, ARC_VAULT_ABI } from "../lib/arc";
import { CONFIG } from "../config";

export default function Home() {
  const [balance, setBalance] = useState<string>("loading");

  useEffect(() => {
    async function load() {
      const raw = await arcClient.readContract({
        address: CONFIG.ARC.vault as `0x${string}`,
        abi: ARC_VAULT_ABI,
        functionName: "totalUSDC",
      });

      setBalance((Number(raw) / 1e6).toFixed(2));
    }

    load();
  }, []);

  return (
    <main style={{ padding: 32 }}>
      <h1>💧 StableFlow</h1>
      <p>ENS: {CONFIG.ENS_NAME}</p>

      <hr />

      <h2>Arc Settlement</h2>
      <p><strong>Arc Vault:</strong> {CONFIG.ARC.vault}</p>
      <p><strong>USDC Balance:</strong> {balance}</p>

      <p>
        <a
          href={`https://testnet.arcscan.app/address/${CONFIG.ARC.vault}`}
          target="_blank"
        >
          View on Arc Explorer →
        </a>
      </p>

      <hr />

      <p>
        Rebalancing intents emitted on Sepolia are finalized
        and settled on Arc using USDC.
      </p>
    </main>
  );
}
