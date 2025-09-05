"use client";

import React, { useEffect, useMemo, useState } from "react";
import api from "../services/api";
import PostCard from "../components/features/PostCard";

type FeedPost = {
  id: string | number;
  title: string;
  description?: string | null;
  price?: number | string | null;
  min_price?: number | null;
  max_price?: number | null;
  currency?: string | null;
  urgency?: string | null;
  distance_m?: number | null;
  distance_km?: number | null;
  category?: string | null; // raw
  post_type?: string | null; // raw
  user?: any;
  tags?: string[];
  inserted_at?: string | null;
  created_at?: string | null;

  /** нормализованная вкладка */
  _category?: "jobs" | "activities";
};

type Filters = {
  q: string;
  priceMin: number | null;
  priceMax: number | null;
  urgentOnly: boolean;
  distanceKm: number | null;
};

const IconSearch = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
    <path
      d="M21 21l-4.35-4.35M10 18a8 8 0 1 1 0-16 8 8 0 0 1 0 16Z"
      stroke="url(#g)"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    <defs>
      <linearGradient id="g" x1="0" y1="0" x2="24" y2="24">
        <stop stopColor="#3B82F6" />
        <stop offset="1" stopColor="#9333EA" />
      </linearGradient>
    </defs>
  </svg>
);

const IconFilter = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
    <path d="M3 5h18M6 12h12M10 19h4" stroke="#374151" strokeWidth="2" strokeLinecap="round" />
  </svg>
);

export default function HomePage() {
  const [tab, setTab] = useState<"jobs" | "activities">("jobs");

  const [items, setItems] = useState<FeedPost[]>([]);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [filters, setFilters] = useState<Filters>({
    q: "",
    priceMin: null,
    priceMax: null,
    urgentOnly: false,
    distanceKm: null,
  });
  const [filtersOpen, setFiltersOpen] = useState(false);

  function toNumberOrNull(v: any): number | null {
    if (v === null || v === undefined || v === "") return null;
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  }

  function normalizeTabByCategory(rawType?: string | null, rawCat?: string | null): "jobs" | "activities" | undefined {
    const t = String(rawType ?? "").toLowerCase().trim();
    const c = String(rawCat ?? "").toLowerCase().trim();

    if (["job", "jobs", "work", "работа"].includes(t) || ["job", "jobs", "work", "работа"].includes(c)) return "jobs";
    if (
      ["activity", "activities", "event", "events", "событие"].includes(t) ||
      ["activity", "activities", "event", "events", "событие"].includes(c)
    )
      return "activities";
    return undefined;
  }

  function normalizePosts(res: any): FeedPost[] {
    const list =
      (res && Array.isArray(res.items) && res.items) ||
      (res && Array.isArray(res.data) && res.data) ||
      (res && Array.isArray(res.posts) && res.posts) ||
      (Array.isArray(res) ? res : []);

    return (list as any[]).map((p, i) => {
      const id = p.id ?? p.uuid ?? i;
      const title = p.title ?? p.name ?? "Untitled";
      const description = p.description ?? p.body ?? null;

      const min_price = toNumberOrNull(p.min_price);
      const max_price = toNumberOrNull(p.max_price);
      const price =
        typeof p.price === "string"
          ? p.price
          : toNumberOrNull(p.price) ??
            (p.price_cents != null ? Number(p.price_cents) / 100 : null) ??
            (min_price != null && max_price != null ? `${min_price}–${max_price}` : null);

      const currency = p.currency ?? null;
      const urgency = p.urgency ?? p.priority ?? null;

      const distance_km = p.distance_km ?? p.distanceKm ?? (p.distance_m != null ? Number(p.distance_m) / 1000 : null);
      const distance_m = p.distance_m ?? (distance_km != null ? Math.round(distance_km * 1000) : null);

      const _category = normalizeTabByCategory(p.post_type, p.category);

      return {
        id,
        title,
        description,
        price,
        min_price,
        max_price,
        currency,
        urgency,
        distance_m,
        distance_km,
        category: p.category ?? null,
        post_type: p.post_type ?? null,
        user: p.user ?? null,
        tags: Array.isArray(p.tags) ? p.tags : [],
        inserted_at: p.inserted_at ?? null,
        created_at: p.created_at ?? null,
        _category,
      };
    });
  }

  async function loadPosts() {
    setLoading(true);
    setErr(null);
    try {
      let res: any = null;

      if (api && typeof (api as any).listPosts === "function") {
        res = await (api as any).listPosts();
      } else if (api && typeof (api as any).getPosts === "function") {
        res = await (api as any).getPosts();
      } else {
        const base = process.env.NEXT_PUBLIC_API_URL?.replace(/\/+$/, "") ?? "";
        const r = await fetch(`${base}/api/posts`, { cache: "no-store" });
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        res = await r.json();
      }

      setItems(normalizePosts(res));
    } catch (e: any) {
      setErr(e?.message || "Failed to load");
      setItems([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadPosts();
  }, []);

  useEffect(() => {
    setFilters((s) => ({ ...s, q: search }));
  }, [search]);

  const matches = (p: FeedPost, f: Filters, currentTab: "jobs" | "activities") => {
    if (!p) return false;

    // вкладка
    if (currentTab === "jobs") {
      if (p._category && p._category !== "jobs") return false;
      if (!p._category) {
        // если не нормализовалось, смотрим post_type/category "job"
        const t = (p.post_type || p.category || "").toLowerCase();
        if (!["job", "jobs", "work", "работа"].some((w) => t.includes(w))) return false;
      }
    } else {
      if (p._category && p._category !== "activities") return false;
      if (!p._category) {
        const t = (p.post_type || p.category || "").toLowerCase();
        if (!["activity", "activities", "event", "events", "событие"].some((w) => t.includes(w))) return false;
      }
    }

    if (f.urgentOnly) {
      const isUrgent = p.urgency === "today" || p.urgency === "urgent";
      if (!isUrgent) return false;
    }

    if (p.price != null && typeof p.price !== "string") {
      if (f.priceMin != null && Number(p.price) < f.priceMin) return false;
      if (f.priceMax != null && Number(p.price) > f.priceMax) return false;
    }

    if (f.distanceKm != null && p.distance_km != null && p.distance_km > f.distanceKm) return false;

    if (f.q && f.q.trim().length > 0) {
      const q = f.q.toLowerCase();
      const inTitle = (p.title || "").toLowerCase().includes(q);
      const inDesc = (p.description || "").toLowerCase().includes(q);
      if (!inTitle && !inDesc) return false;
    }

    return true;
  };

  const visible = useMemo(() => {
    if (!Array.isArray(items)) return [];
    return items.filter((p) => matches(p, filters, tab));
  }, [items, filters, tab]);

  return (
    <div className="px-4 sm:px-6 lg:px-8 py-4">
      {/* Верхняя панель: вкладки + поиск + кнопка фильтрации */}
      <div className="flex items-center gap-3">
        {/* Tabs */}
        <div className="flex items-center rounded-2xl border bg-white p-1">
          <button
            className={`h-10 px-4 rounded-xl font-medium ${
              tab === "jobs" ? "bg-blue-600 text-white shadow-sm" : "text-gray-700"
            }`}
            onClick={() => setTab("jobs")}
          >
            Jobs
          </button>
          <button
            className={`h-10 px-4 rounded-xl font-medium ${
              tab === "activities" ? "bg-blue-600 text-white shadow-sm" : "text-gray-700"
            }`}
            onClick={() => setTab("activities")}
          >
            Activities
          </button>
        </div>

        {/* Search */}
        <div className="flex-1 min-w-0">
          <div className="h-12 rounded-2xl border bg-white px-3 sm:px-4 flex items-center gap-2">
            <IconSearch />
            <input
              className="w-full min-w-0 outline-none bg-transparent placeholder:text-gray-400"
              placeholder="Search..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        {/* Кнопка фильтрации (открывает правый дровер) */}
        <button
          type="button"
          onClick={() => setFiltersOpen(true)}
          className="h-12 w-12 rounded-2xl border bg-white flex items-center justify-center"
          aria-label="Filters"
        >
          <IconFilter />
        </button>
      </div>

      {/* Чипы активных фильтров */}
      <div className="mt-4 flex flex-wrap items-center gap-2">
        {filters.priceMin != null || filters.priceMax != null ? (
          <span className="text-blue-600/90 bg-blue-50 border border-blue-200 rounded-2xl px-3 py-1 text-sm">
            Price: {filters.priceMin ?? "0"}–{filters.priceMax ?? "∞"}
          </span>
        ) : null}
        {filters.distanceKm != null ? (
          <span className="text-blue-600/90 bg-blue-50 border border-blue-200 rounded-2xl px-3 py-1 text-sm">
            Distance: 0–{filters.distanceKm}km
          </span>
        ) : null}
        {filters.urgentOnly ? (
          <span className="text-blue-600/90 bg-blue-50 border border-blue-200 rounded-2xl px-3 py-1 text-sm">Urgent</span>
        ) : null}
      </div>

      {/* Лента */}
      <div className="mt-4">
        {loading && <div className="text-gray-500">Loading…</div>}
        {err && <div className="text-red-600">{err}</div>}

        {!loading && !err && (
          <>
            {visible.length === 0 ? (
              <div className="text-gray-500 px-2 py-6">Ничего не найдено по текущим фильтрам</div>
            ) : (
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                {visible.map((post) => (
                  <PostCard key={String(post.id)} post={post} />
                ))}
              </div>
            )}
          </>
        )}
      </div>

      {/* Правый дровер фильтров */}
      {filtersOpen && (
        <div className="fixed inset-0 z-40" aria-modal="true" role="dialog">
          <div className="absolute inset-0 bg-black/30" onClick={() => setFiltersOpen(false)} />
          <div className="absolute right-0 top-0 h-full w-full sm:w-[520px] bg-white shadow-xl p-4 sm:p-6 overflow-y-auto">
            <div className="flex items-center justify-between">
              <div className="text-lg font-semibold">Filters</div>
              <button onClick={() => setFiltersOpen(false)} className="h-9 px-3 rounded-xl border bg-white">
                Close
              </button>
            </div>

            <div className="mt-4 grid gap-5">
              {/* Диапазон цены */}
              <div>
                <label className="text-sm text-gray-500">Price range</label>
                <div className="mt-2 flex items-center gap-3">
                  <div className="flex items-center gap-2 rounded-2xl border bg-white px-3 w-32">
                    <input
                      className="w-full h-10 outline-none bg-transparent placeholder:text-gray-400"
                      placeholder="Min"
                      type="number"
                      value={filters.priceMin ?? ""}
                      onChange={(e) =>
                        setFilters((s) => ({
                          ...s,
                          priceMin: e.target.value === "" ? null : Number(e.target.value),
                        }))
                      }
                    />
                  </div>
                  <span className="text-gray-400">—</span>
                  <div className="flex items-center gap-2 rounded-2xl border bg-white px-3 w-32">
                    <input
                      className="w-full h-10 outline-none bg-transparent placeholder:text-gray-400"
                      placeholder="Max"
                      type="number"
                      value={filters.priceMax ?? ""}
                      onChange={(e) =>
                        setFilters((s) => ({
                          ...s,
                          priceMax: e.target.value === "" ? null : Number(e.target.value),
                        }))
                      }
                    />
                  </div>
                </div>
              </div>

              {/* Дистанция */}
              <div>
                <label className="text-sm text-gray-500">Distance (km)</label>
                <div className="mt-2 flex items-center gap-2">
                  <input
                    type="range"
                    min={0}
                    max={20}
                    className="w-full"
                    value={filters.distanceKm ?? 0}
                    onChange={(e) =>
                      setFilters((s) => ({
                        ...s,
                        distanceKm: Number(e.target.value) || 0,
                      }))
                    }
                  />
                  <div className="w-14 text-right text-sm text-gray-700">{filters.distanceKm ?? 0}km</div>
                </div>
              </div>

              {/* Urgent only */}
              <div className="flex items-center justify-between">
                <label className="inline-flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    className="h-4 w-4"
                    checked={filters.urgentOnly}
                    onChange={(e) => setFilters((s) => ({ ...s, urgentOnly: e.target.checked }))}
                  />
                  Urgent only
                </label>

                <button
                  className="inline-flex items-center justify-center rounded-2xl font-medium transition focus:outline-none border border-gray-300 bg-white hover:bg-gray-50 h-10 px-4"
                  onClick={() =>
                    setFilters({
                      q: search || "",
                      priceMin: null,
                      priceMax: null,
                      urgentOnly: false,
                      distanceKm: null,
                    })
                  }
                >
                  Reset filters
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
