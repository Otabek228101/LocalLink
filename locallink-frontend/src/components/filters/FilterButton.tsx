"use client";

export default function FilterButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label="Filters"
      className="inline-flex h-10 items-center gap-2 rounded-xl border bg-white px-3 shadow-sm hover:bg-slate-50"
    >
      {/* иконка «воронка» из вашего скрина */}
      <svg width="18" height="18" viewBox="0 0 24 24" stroke="currentColor" fill="none">
        <path d="M3 5h18l-7 8v4l-4 2v-6L3 5z" strokeWidth="1.8" strokeLinejoin="round" />
      </svg>
      <span className="hidden sm:inline">Filters</span>
    </button>
  );
}
