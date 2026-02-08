import "./globals.css";
import { ENSConfiguration } from "@/components/ENSConfiguration";
import { ArcVaultStatus } from "@/components/ArcVaultStatus";
import { IntentFeed } from "@/components/IntentFeed";
import { NetworkIndicator } from "@/components/NetworkIndicator";

export default async function Page() {
  return (
    <main className="min-h-screen bg-[#09090b] text-white selection:bg-cyan-500/30 overflow-hidden">
      {/* Background Mesh */}
      <div className="fixed inset-0 z-0">
        <div className="mesh-gradient absolute top-[-20%] left-[-10%] h-[700px] w-[700px] rounded-full bg-cyan-600/20" />
        <div className="mesh-gradient absolute bottom-[-20%] right-[-10%] h-[700px] w-[700px] rounded-full bg-purple-600/10" />
      </div>

      <div className="relative z-10 mx-auto max-w-7xl px-6 py-12 lg:px-8">
        <header className="flex flex-col justify-between gap-8 md:flex-row md:items-end mb-20 px-2">
          <div className="space-y-5">
            <h1 className="text-7xl font-[1000] tracking-tighter logo-glow">
              STABLE<span className="bg-gradient-to-b from-cyan-300 to-cyan-500 bg-clip-text text-transparent">FLOW</span>
            </h1>
            <p className="text-zinc-500 font-mono text-xs uppercase tracking-[0.3em] flex items-center gap-3">
              <span className="h-[1px] w-8 bg-cyan-500/30" />
              Cross-chain Intent Layer
            </p>
          </div>
          <NetworkIndicator />
        </header>

        <div className="grid gap-8 lg:grid-cols-12">
          <div className="lg:col-span-8 flex flex-col gap-8">
            <ArcVaultStatus />
            <ENSConfiguration />
          </div>

          <aside className="lg:col-span-4 max-h-[900px] overflow-hidden">
            <IntentFeed />
          </aside>
        </div>
      </div>
    </main>
  );
}