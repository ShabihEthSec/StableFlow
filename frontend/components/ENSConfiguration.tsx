import { resolveENS } from "@/lib/ens";
import { Card } from "./Card";
import { Settings, ExternalLink } from "lucide-react";

export async function ENSConfiguration() {
  const name = process.env.NEXT_PUBLIC_PROTOCOL_ENS!;
  const config = await resolveENS(name);

  if (!config) {
    return <Card title="ENS Configuration">Resolver not found</Card>;
  }

  return (
    <Card title="Protocol Control Plane" icon={<Settings className="h-4 w-4" />}>
      <div className="grid gap-y-8">
        {/* Header with Name */}
        <div className="flex items-center justify-between border-b border-white/5 pb-6">
          <div className="space-y-2">
            <p className="text-xs uppercase font-bold text-zinc-500 tracking-wide">
              Active ENS Identity
            </p>
            <p className="font-mono text-3xl font-black text-red-500/90 drop-shadow-[0_0_12px_rgba(239,68,68,0.4)] tracking-tight">
              {name}
            </p>
          </div>
          <a
            href={`https://sepolia.app.ens.domains/${name}`}
            target="_blank"
            rel="noopener noreferrer"
            className="group flex items-center gap-2.5 rounded-full bg-white/5 border border-white/10 px-5 py-2.5 text-sm font-semibold text-zinc-300 hover:bg-white/10 hover:border-white/20 transition-all"
          >
            <span>Explorer</span>
            <ExternalLink className="h-4 w-4 opacity-50 group-hover:opacity-100 group-hover:translate-x-0.5 transition-all" />
          </a>
        </div>

        {/* Data Grid */}
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
          <ConfigItem label="System Status" value={config.status} isBadge />
          <ConfigItem label="Execution Mode" value={config.mode} />
          <ConfigItem label="Safety Threshold" value={`${config.threshold} bps`} />
          <ConfigItem label="Target Contract" value={config.execution} isMono />
          <ConfigItem
            label="Authorized Executor"
            value={config.executor}
            isMono
            className="sm:col-span-2"
          />
          <ConfigItem
            label="Hook Implementation"
            value={config.hook}
            isMono
            className="sm:col-span-2"
          />
        </div>
      </div>
    </Card>
  );
}

function ConfigItem({
  label,
  value,
  isMono,
  isBadge,
  className = "",
}: {
  label: string;
  value: string;
  isMono?: boolean;
  isBadge?: boolean;
  className?: string;
}) {
  const isActive = value === "active";

  return (
    <div className={`flex flex-col gap-2.5 ${className}`}>
      <span className="text-xs uppercase font-bold text-zinc-500 tracking-wide flex items-center gap-2">
        <div className="h-1 w-1 rounded-full bg-zinc-600"></div>
        {label}
      </span>

      {isBadge ? (
        <span
          className={`inline-flex w-fit items-center gap-2 rounded-full px-4 py-1.5 text-xs font-bold uppercase tracking-tight
            ${
              isActive
                ? "bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 shadow-[0_0_15px_rgba(16,185,129,0.15)]"
                : "bg-red-500/10 border border-red-500/20 text-red-400 shadow-[0_0_15px_rgba(239,68,68,0.15)]"
            }
          `}
        >
          <span
            className={`h-1.5 w-1.5 rounded-full animate-pulse ${
              isActive ? "bg-emerald-500" : "bg-red-500"
            }`}
          />
          {value}
        </span>
      ) : (
        <div
          className={`${
            isMono
              ? "font-mono text-sm bg-white/[0.03] p-4 rounded-xl border border-white/5 truncate text-cyan-200/70 transition-colors hover:text-cyan-200 hover:border-white/10"
              : "font-semibold text-base text-zinc-200"
          }`}
        >
          {value}
        </div>
      )}
    </div>
  );
}
