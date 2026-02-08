export function NetworkIndicator() {
  return (
    <div className="flex flex-wrap gap-3">
      <StatusBadge
        name="Ethereum Sepolia"
        active
        href="https://sepolia.etherscan.io/address/0x6cbc5627c02c69302C2453aD8b7Fb29FD91680C0#code"
      />
      <StatusBadge name="Arc Testnet" active />
    </div>
  );
}

function StatusBadge({
  name,
  active,
  href,
}: {
  name: string;
  active?: boolean;
  href?: string;
}) {
  const badge = (
    <div className="flex cursor-default items-center gap-2.5 rounded-full border border-zinc-800 bg-black/40 px-5 py-2 text-sm font-medium text-zinc-300 backdrop-blur-md transition hover:border-zinc-700">
      <span className="relative flex h-2 w-2">
        {active && (
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-500 opacity-75"></span>
        )}
        <span
          className={`relative inline-flex h-2 w-2 rounded-full ${
            active
              ? "bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.6)]"
              : "bg-zinc-600"
          }`}
        ></span>
      </span>
      {name}
      {href && (
        <span className="ml-1 text-zinc-500 text-xs">↗</span>
      )}
    </div>
  );

  if (href) {
    return (
      <a
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-block"
      >
        {badge}
      </a>
    );
  }

  return badge;
}
