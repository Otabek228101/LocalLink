"use client";

type Props = {
  priceMin?: number;
  priceMax?: number;
  setPriceMin: (v?: number) => void;
  setPriceMax: (v?: number) => void;
  distanceKm?: number;
  setDistanceKm: (v?: number) => void;
  urgentOnly?: boolean;
  setUrgentOnly: (v?: boolean) => void;
  onReset: () => void;
  onApply?: () => void;
};

export default function FiltersPanel({
  priceMin,
  priceMax,
  setPriceMin,
  setPriceMax,
  distanceKm,
  setDistanceKm,
  urgentOnly,
  setUrgentOnly,
  onReset,
  onApply,
}: Props) {
  return (
    <div className="grid gap-4">
      <div className="grid gap-4 rounded-2xl border bg-white p-4 md:grid-cols-3">
        <div>
          <label className="text-sm text-gray-500">Диапазон цены (SUM)</label>
          <div className="mt-2 flex items-center gap-2">
            <div className="flex w-28 items-center gap-2 rounded-2xl border bg-white px-3">
              <input
                className="h-10 w-full bg-transparent outline-none placeholder:text-gray-400"
                placeholder="Min"
                type="number"
                value={priceMin ?? ""}
                onChange={(e) =>
                  setPriceMin(e.target.value ? Number(e.target.value) : undefined)
                }
              />
            </div>
            <span className="text-gray-400">—</span>
            <div className="flex w-28 items-center gap-2 rounded-2xl border bg-white px-3">
              <input
                className="h-10 w-full bg-transparent outline-none placeholder:text-gray-400"
                placeholder="Max"
                type="number"
                value={priceMax ?? ""}
                onChange={(e) =>
                  setPriceMax(e.target.value ? Number(e.target.value) : undefined)
                }
              />
            </div>
          </div>
        </div>

        <div>
          <label className="text-sm text-gray-500">Дистанция (км)</label>
          <div className="mt-2 flex items-center gap-2">
            <input
              min={0}
              max={20}
              className="w-full"
              type="range"
              value={distanceKm ?? 0}
              onChange={(e) => setDistanceKm(Number(e.target.value))}
            />
            <div className="w-14 text-right text-sm text-gray-700">{distanceKm ?? 0}км</div>
          </div>
        </div>

        <div className="flex items-end justify-between gap-3">
          <label className="inline-flex items-center gap-2 text-sm">
            <input
              className="h-4 w-4"
              type="checkbox"
              checked={!!urgentOnly}
              onChange={(e) => setUrgentOnly(e.target.checked)}
            />
            Только срочные
          </label>

          <button
            onClick={onReset}
            className="h-10 rounded-2xl border border-gray-300 bg-white px-4 font-medium transition hover:bg-gray-50"
          >
            Сбросить
          </button>
        </div>
      </div>

      <div className="flex justify-end gap-3">
        <button
          onClick={onApply}
          className="h-10 rounded-2xl bg-blue-600 px-5 font-medium text-white hover:bg-blue-700"
        >
          Показать результаты
        </button>
      </div>
    </div>
  );
}
