import React from "react";

type Props = {
  post: any;
};

function timeAgo(ts?: string | null) {
  if (!ts) return null;
  const d = new Date(ts);
  if (isNaN(d.getTime())) return null;
  const diff = Math.floor((Date.now() - d.getTime()) / 1000);
  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

export default function PostCard({ post }: Props) {
  const data = post ?? {};

  // Автор
  const author =
    (data.user && [data.user.first_name, data.user.last_name].filter(Boolean).join(" ")) ||
    data.user?.name ||
    data.author ||
    null;

  // Цена
  let priceLabel: string | null = null;
  if (typeof data.price === "string") priceLabel = data.price;
  else if (typeof data.price === "number") priceLabel = `$${data.price}`;
  else if (data.min_price != null && data.max_price != null) priceLabel = `$${data.min_price}–${data.max_price}`;

  // Срочность
  const urgent = String(data.urgency || "").toLowerCase();
  const isUrgent = urgent === "urgent" || urgent === "today";

  // Дистанция
  const meter = data.distance_m ?? (data.distance_km != null ? Math.round(data.distance_km * 1000) : null);
  const distanceLabel = meter != null ? (meter >= 1000 ? `${(meter / 1000).toFixed(1)}km` : `${meter}m`) : null;

  // Категория/тег
  const categoryChip =
    (Array.isArray(data.tags) && data.tags[0]) || data.category || data.post_type || undefined;

  const createdAt = data.inserted_at || data.created_at || null;
  const ago = timeAgo(createdAt);

  return (
    <div className="rounded-3xl border border-gray-200 bg-white p-4 shadow-sm hover:shadow-md transition">
      {/* Заголовок */}
      <div className="text-[17px] font-semibold text-gray-900 leading-snug">{data.title ?? "Untitled"}</div>

      {/* Автор */}
      {author && (
        <div className="mt-1 flex items-center gap-2 text-[13px] text-gray-600">
          <span className="h-2 w-2 rounded-full bg-blue-500 inline-block" />
          <span className="truncate">{author}</span>
        </div>
      )}

      {/* Пилюли */}
      <div className="mt-3 flex flex-wrap items-center gap-2">
        {priceLabel && (
          <span className="inline-flex items-center rounded-full bg-emerald-500 text-white px-3 py-1 text-[12px] font-semibold">
            {priceLabel}
          </span>
        )}

        {isUrgent && (
          <span className="inline-flex items-center rounded-full bg-red-100 text-red-600 px-3 py-1 text-[12px] font-medium">
            Urgent
          </span>
        )}

        {distanceLabel && (
          <span className="inline-flex items-center rounded-full bg-blue-100 text-blue-700 px-3 py-1 text-[12px] font-medium">
            {distanceLabel}
          </span>
        )}

        {categoryChip && (
          <span className="inline-flex items-center rounded-full bg-amber-100 text-amber-700 px-3 py-1 text-[12px] font-medium">
            {String(categoryChip)}
          </span>
        )}
      </div>

      {/* Разделитель */}
      <div className="mt-3 h-px bg-gray-200" />

      {/* Низ карточки */}
      <div className="mt-3 flex items-center justify-between">
        <div className="text-xs text-gray-500">{ago ?? ""}</div>
        <button
          type="button"
          className="h-9 px-4 rounded-full bg-blue-600 text-white text-sm font-semibold shadow-sm hover:bg-blue-700 transition"
        >
          Contact
        </button>
      </div>
    </div>
  );
}
