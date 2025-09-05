"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const Item = ({
  href,
  label,
  icon,
  active,
}: {
  href: string;
  label: string;
  icon: React.ReactNode;
  active?: boolean;
}) => (
  <Link
    href={href}
    className={`flex flex-col items-center justify-center gap-1 px-3 py-2 text-xs transition ${
      active ? "text-blue-600" : "text-slate-600 hover:text-slate-900"
    }`}
  >
    <span className={`h-6 w-6 ${active ? "opacity-100" : "opacity-80"}`}>{icon}</span>
    {label}
  </Link>
);

export default function BottomTabBar() {
  const pathname = usePathname();

  return (
    <nav className="fixed inset-x-0 bottom-0 z-40 border-t bg-white/95 backdrop-blur">
      <div className="mx-auto flex h-[72px] max-w-6xl items-center justify-between px-4">
        <Item
          href="/"
          label="Jobs"
          active={pathname === "/"}
          icon={
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path d="M10 6h4m-9 4h14v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7Zm3-4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v4H7V6Z" strokeWidth="1.8" />
            </svg>
          }
        />
        <Item
          href="/events"
          label="Events"
          active={pathname?.startsWith("/events")}
          icon={
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path d="M16 2v4M8 2v4M3 10h18M5 6h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2Z" strokeWidth="1.8" />
            </svg>
          }
        />
        {/* Центральная большая кнопка как на макете */}
        <Link
          href="/create-post"
          className="relative -mt-8 inline-flex h-14 w-14 items-center justify-center rounded-full bg-blue-600 text-white shadow-lg ring-4 ring-blue-100 hover:bg-blue-700"
          aria-label="Create"
          title="Create"
        >
          <svg viewBox="0 0 24 24" width="26" height="26" fill="currentColor">
            <path d="M11 5h2v14h-2zM5 11h14v2H5z" />
          </svg>
        </Link>
        <Item
          href="/messages"
          label="Message"
          active={pathname?.startsWith("/messages")}
          icon={
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path d="M4 5h16v10H7l-3 3V5Z" strokeWidth="1.8" />
            </svg>
          }
        />
        <Item
          href="/profile"
          label="Profile"
          active={pathname?.startsWith("/profile")}
          icon={
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path d="M12 12a4 4 0 1 0-4-4 4 4 0 0 0 4 4Zm-8 8a8 8 0 0 1 16 0" strokeWidth="1.8" />
            </svg>
          }
        />
      </div>
    </nav>
  );
}
