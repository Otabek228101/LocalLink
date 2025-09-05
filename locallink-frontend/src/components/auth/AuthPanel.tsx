"use client";

import Link from "next/link";
import type { User } from "../../services/api";

type Props = {
  user: User | null;
  onLogout?: () => void;
};

export default function AuthPanel({ user, onLogout }: Props) {
  if (!user) {
    return (
      <div className="flex items-center gap-2">
        <Link
          href="/login"
          className="inline-flex h-9 items-center rounded-xl px-3 text-sm hover:bg-gray-100"
        >
          Login
        </Link>
        <Link
          href="/register"
          className="inline-flex h-9 items-center rounded-xl bg-gray-900 px-4 text-sm font-medium text-white hover:bg-black"
        >
          Sign up
        </Link>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-2">
      <Link
        href="/profile"
        className="inline-flex h-9 items-center rounded-xl px-3 text-sm hover:bg-gray-100"
      >
        {(user.first_name || user.email)?.[0]?.toUpperCase() ?? "U"}
      </Link>
      <button
        onClick={onLogout}
        className="inline-flex h-9 items-center rounded-xl px-3 text-sm hover:bg-gray-100"
      >
        Logout
      </button>
    </div>
  );
}
