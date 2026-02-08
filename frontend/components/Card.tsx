import { ReactNode } from "react";

interface CardProps {
  title: string;
  children: ReactNode;
  icon?: ReactNode;
  className?: string;
}

export function Card({ title, children, icon, className = "" }: CardProps) {
  return (
    <div className={`flex flex-col rounded-2xl glass-card transition-all duration-300 hover:border-zinc-700/50 ${className}`}>
      <div className="flex items-center gap-3 border-b border-white/5 px-7 py-5">
        {icon && <span className="text-cyan-400/80">{icon}</span>}
        <h2 className="text-xs font-bold uppercase tracking-[0.15em] text-zinc-400">
          {title}
        </h2>
      </div>
      <div className="p-7">{children}</div>
    </div>
  );
}