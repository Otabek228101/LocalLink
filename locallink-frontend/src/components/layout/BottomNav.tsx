// src/components/layout/BottomNav.tsx
"use client";

import Link from "next/link";
import { IconMap, IconFlame, IconBriefcase, IconMessage, IconUser } from "../ui/icons";

const Item = ({ href, label, icon }: { href: string; label: string; icon: React.ReactNode }) => (
  <Link href={href} className="flex flex-col items-center justify-center text-[11px] text-slate-600 w-16">
    <div className="w-6 h-6">{icon}</div>
    <span className="mt-1">{label}</span>
  </Link>
);

export default function BottomNav() {
  return (
    <nav className="ll-bnav">
      <div className="max-w-6xl mx-auto h-16 flex items-center justify-between px-6 relative">
        <Item href="/map" label="Map" icon={<IconMap className="w-6 h-6" />} />
        <Item href="/events" label="Events" icon={<IconFlame className="w-6 h-6" />} />

        {/* FAB */}
        <Link href="/create-post" className="ll-fab" aria-label="Create">
          <IconBriefcase className="w-8 h-8 text-blue-600" />
        </Link>

        <Item href="/messages" label="Message" icon={<IconMessage className="w-6 h-6" />} />
        <Item href="/profile" label="Profile" icon={<IconUser className="w-6 h-6" />} />
      </div>
    </nav>
  );
}
