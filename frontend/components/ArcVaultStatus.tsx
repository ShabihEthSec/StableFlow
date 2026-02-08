import { getUSDCBalance } from "@/lib/arc";
import { Card } from "./Card";
import { Activity, ExternalLink } from "lucide-react";

export async function ArcVaultStatus() {
  const vault = process.env.NEXT_PUBLIC_ARC_VAULT!;
  const balance = await getUSDCBalance(vault);

  return (
    <Card title="Liquidity Hub" icon={<Activity className="h-4 w-4" />}>
      <div className="flex flex-col gap-2">
        <span className="text-xs font-bold text-zinc-500 uppercase tracking-wide">
          Total Vault Balance
        </span>
        <div className="text-6xl font-black tracking-tight text-white">
          {balance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}{" "}
          <span className="text-3xl text-cyan-400/60">USDC</span>
        </div>
      </div>

      <div className="mt-8 flex flex-col gap-4 rounded-xl bg-white/5 p-5 border border-white/5 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-3">
          <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse shadow-[0_0_10px_rgba(16,185,129,0.5)]" />
          <span className="text-sm font-semibold text-zinc-300 tracking-tight">
            Active on Arc Network
          </span>
        </div>
        <a
          href={`https://testnet.arcscan.app/address/${vault}`}
          target="_blank"
          rel="noopener noreferrer"
          className="text-sm font-semibold text-cyan-400 hover:text-cyan-300 transition-colors uppercase flex items-center gap-2 group"
        >
          Explorer 
          <ExternalLink className="h-4 w-4 group-hover:translate-x-0.5 transition-transform" />
        </a>
      </div>
    </Card>
  );
}