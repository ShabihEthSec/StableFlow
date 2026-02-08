import { Card } from "./Card";
import { GitCommit } from "lucide-react";

export function IntentFeed() {
  return (
    <Card title="Intent Execution Trace" icon={<GitCommit className="h-4 w-4" />}>
      <div className="relative border-l-2 border-cyan-500/30 ml-3 space-y-8 py-2">
        <TimelineItem
          title="Intent Emitted"
          desc="Rebalance intent emitted by Uniswap v4 hook"
          network="Sepolia"
          active={true}
        />
        <TimelineItem
          title="Validated & Executed"
          desc="Marked executed via Execution Registry"
          network="Sepolia"
          active={true}
        />
        <TimelineItem
          title="Settlement Finalized"
          desc="Funds settled via Arc Liquidity Hub"
          network="Arc Testnet"
          active={true}
          isLast
        />
      </div>

      <div className="mt-8 flex items-center gap-3 rounded-xl bg-cyan-500/5 border border-cyan-500/20 p-4 text-sm text-cyan-300/90">
        <div className="h-2 w-2 rounded-full bg-cyan-500 animate-pulse shadow-[0_0_10px_rgba(6,182,212,0.5)]" />
        Real-time feed of cross-chain settlement flow.
      </div>
    </Card>
  );
}

function TimelineItem({ 
  title, 
  desc, 
  network, 
  active, 
  isLast 
}: { 
  title: string; 
  desc: string; 
  network: string; 
  active?: boolean; 
  isLast?: boolean;
}) {
  return (
    <div className={`relative pl-8 ${!isLast ? 'pb-2' : ''}`}>
      {/* Dot */}
      <span className={`absolute -left-[9px] top-1 h-4 w-4 rounded-full border-2 ${
        active 
          ? "bg-cyan-500 border-cyan-400 shadow-[0_0_12px_rgba(6,182,212,0.6)]" 
          : "bg-zinc-700 border-zinc-600"
      }`} />
      
      <div className="flex flex-col gap-1.5">
        <div className="flex items-center gap-2.5 flex-wrap">
          <span className="text-base font-semibold text-zinc-100">{title}</span>
          <span className="rounded-md bg-white/5 border border-white/10 px-2.5 py-1 text-xs font-semibold text-zinc-400">
            {network}
          </span>
        </div>
        <span className="text-sm text-zinc-400 leading-relaxed">{desc}</span>
      </div>
    </div>
  );
}