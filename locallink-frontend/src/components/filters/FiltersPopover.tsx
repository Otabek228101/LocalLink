"use client";

import { useEffect, useRef } from "react";

export type FiltersState = {
  priceMin?: number;
  priceMax?: number;
  distanceKm: number;
  urgentOnly: boolean;
};

export default function FiltersPopover({
  open,
  onClose,
  value,
  onChange,
}: {
  open: boolean;
  onClose: () => void;
  value: FiltersState;
  onChange: (v: FiltersState) => void;
}) {
  const ref = useRef<HTMLDivElement | null>(null);

  // клик вне поповера
  useEffect(() => {
    function onDoc(e: MouseEvent) {
      if (!ref.current) return;
      if (!ref.current.contains(e.target as Node)) onClose();
    }
    if (open) document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      ref={ref}
      className="absolute z-50 top-12 md:top-10 left-3 md:left-0 bg-white border border-slate-200 rounded-2xl shadow-xl p-4 w-[calc(100vw-24px)] md:w-[720px]"
    >
      <div className="grid md:grid-cols-3 gap-4">
        <div>
          <label className="text-sm text-gray-500">Price range ($)</label>
          <div className="mt-2 flex items-center gap-2">
            <div className="flex items-center gap-2 rounded-2xl border bg-white px-3 w-28">
              <input
                className="w-full h-10 outline-none bg-transparent placeholder:text-gray-400"
                placeholder="Min"
                type="number"
                value={value.priceMin ?? ""}
                onChange={(e) => onChange({ ...value, priceMin: e.target.value ? Number(e.target.value) : undefined })}
              />
            </div>
            <span className="text-gray-400">—</span>
            <div className="flex items-center gap-2 rounded-2xl border bg-white px-3 w-28">
              <input
                className="w-full h-10 outline-none bg-transparent placeholder:text-gray-400"
                placeholder="Max"
                type="number"
                value={value.priceMax ?? ""}
                onChange={(e) => onChange({ ...value, priceMax: e.target.value ? Number(e.target.value) : undefined })}
              />
            </div>
          </div>
        </div>

        <div>
          <label className="text-sm text-gray-500">Distance (km)</label>
          <div className="mt-2 flex items-center gap-2">
            <input
              type="range"
              min={0}
              max={20}
              value={value.distanceKm}
              onChange={(e) => onChange({ ...value, distanceKm: Number(e.target.value) })}
              className="w-full"
            />
            <div className="w-14 text-right text-sm text-gray-700">{value.distanceKm}km</div>
          </div>
        </div>

        <div className="flex items-end justify-between md:justify-start gap-3">
          <label className="inline-flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              className="h-4 w-4"
              checked={value.urgentOnly}
              onChange={(e) => onChange({ ...value, urgentOnly: e.target.checked })}
            />
            Urgent only
          </label>

          <button
            className="inline-flex items-center justify-center rounded-2xl font-medium transition focus:outline-none border border-gray-300 bg-white hover:bg-gray-50 h-10 px-4"
            onClick={() => onChange({ priceMin: undefined, priceMax: undefined, distanceKm: 0, urgentOnly: false })}
          >
            Reset filters
          </button>
        </div>
      </div>
    </div>
  );
}
