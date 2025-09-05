"use client";

import { useEffect } from "react";

export default function FiltersSheet({
  open,
  onClose,
  children,
}: {
  open: boolean;
  onClose: () => void;
  children: React.ReactNode;
}) {
  useEffect(() => {
    function onEsc(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    if (open) document.addEventListener("keydown", onEsc);
    return () => document.removeEventListener("keydown", onEsc);
  }, [open, onClose]);

  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50">
      <div className="absolute inset-0 bg-black/30" onClick={onClose} />
      {/* mobile: bottom-sheet, desktop: центрированный модал */}
      <div className="absolute inset-x-0 bottom-0 mx-auto w-full max-w-3xl rounded-t-2xl bg-white p-4 shadow-2xl md:top-1/2 md:bottom-auto md:-translate-y-1/2 md:rounded-2xl">
        <div className="mb-3 flex items-center justify-between">
          <div className="text-base font-semibold">Фильтры</div>
          <button
            onClick={onClose}
            className="rounded-xl border px-3 py-1.5 text-sm hover:bg-gray-50"
          >
            Закрыть
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
