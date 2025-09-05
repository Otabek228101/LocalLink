'use client';

import React, { useEffect, useState } from 'react';
import AppLayout from '../../components/layout/AppLayout';
import apiService, { Post, ListResponse } from '../../services/api';

export default function MapPage() {
  const [items, setItems] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const resp = (await apiService.listPosts({ per_page: 50 })) as ListResponse<Post>;
        const arr = Array.isArray(resp?.data) ? resp.data : [];
        setItems(arr);
      } catch (e: any) {
        setError(e?.message ?? 'Не удалось загрузить посты');
        setItems([]); // гарантируем массив
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <AppLayout>
      <div className="grid gap-4">
        <h1 className="text-xl font-semibold">Карта</h1>

        {loading && <div className="text-gray-500">Загрузка…</div>}
        {error && <div className="text-red-600 text-sm">{error}</div>}

        {!loading && !error && items.length === 0 && (
          <div className="text-gray-500">Нет постов для отображения</div>
        )}

        {/* Временно список — чтобы было, что рендерить.
            Когда подключите карту, используйте эти данные как маркеры. */}
        <ul className="grid gap-3">
          {items.map((p) => (
            <li key={p.id} className="rounded-2xl border bg-white p-4">
              <div className="font-medium">{p.title}</div>
              <div className="text-sm text-gray-600 mt-1 line-clamp-2">
                {p.description}
              </div>
              <div className="text-sm mt-2">
                {p.price} {p.currency} • {p.category} • {p.urgency}
              </div>
            </li>
          ))}
        </ul>
      </div>
    </AppLayout>
  );
}
