'use client';

import React, { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';

type Category = 'job' | 'activities';
type Urgency = 'today' | 'tomorrow' | 'this_week' | 'flexible';
type Currency = 'UZS' | 'USD' | 'EUR';

type PostPayload = {
  title: string;
  description: string;
  category: Category;
  post_type: 'offer';
  location: string;                  // обязательно
  urgency?: Urgency;
  tags?: string[];
  price?: number | null;             // опционально
  currency?: Currency | null;        // опционально, если price нет — уходит null
  skills_required?: string | null;   // опционально
  duration_estimate?: number | null; // опционально (часы)
  max_distance_km?: number | null;   // опционально
};

type ServerErrors =
  | Record<string, string[] | string>   // стандартный формат Ecto
  | { error?: string; errors?: any }    // иногда оболочка {error, errors}
  | string;                             // или просто строка

/** ===== Хелперы ===== */
const API_BASE =
  process.env.NEXT_PUBLIC_API_URL?.replace(/\/$/, '') || 'http://localhost:4000';

function getTokenFromStorage(): string | null {
  // пробуем популярные ключи
  return (
    localStorage.getItem('auth_token') ||
    localStorage.getItem('access_token') ||
    localStorage.getItem('token')
  );
}

async function createPost(payload: PostPayload) {
  const token = getTokenFromStorage();
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}/api/v1/posts`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ post: payload }), // сервер ждёт ключ post
    credentials: 'include',
  });

  const text = await res.text();
  let data: any = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    // оставим как текст
  }

  if (!res.ok) {
    // пробуем вытащить ошибки в предсказуемый вид
    const errors: ServerErrors =
      (data && (data.errors || data.error || data)) || text || 'Validation failed';
    throw errors;
  }

  return data;
}

/** ===== Наборы опций ===== */
const CATEGORY_OPTIONS: { value: Category; label: string }[] = [
  { value: 'job', label: 'Job' },
  { value: 'activities', label: 'Activities' },
];

const URGENCY_OPTIONS: { value: Urgency; label: string }[] = [
  { value: 'today', label: 'Сегодня' },
  { value: 'tomorrow', label: 'Завтра' },
  { value: 'this_week', label: 'На этой неделе' },
  { value: 'flexible', label: 'Гибко' },
];

const CURRENCY_OPTIONS: { value: Currency; label: string }[] = [
  { value: 'UZS', label: 'UZS' },
  { value: 'USD', label: 'USD' },
  { value: 'EUR', label: 'EUR' },
];

/** ===== Страница ===== */
export default function CreatePostPage() {
  const router = useRouter();

  // поля формы
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState(''); // мин. 10 символов — подсветим пользовательски
  const [category, setCategory] = useState<Category>('activities'); // только 2 категории
  const [urgency, setUrgency] = useState<Urgency>('flexible');

  const [location, setLocation] = useState(''); // обязательное
  const [tagsInput, setTagsInput] = useState(''); // "tag1, tag2" -> ["tag1","tag2"]

  const [priceInput, setPriceInput] = useState(''); // строка -> number|null
  const [currency, setCurrency] = useState<Currency>('UZS');

  const [skillsRequired, setSkillsRequired] = useState(''); // опц.
  const [durationEstimate, setDurationEstimate] = useState(''); // часы, опц.
  const [maxDistanceKm, setMaxDistanceKm] = useState(''); // км, опц.

  const [submitting, setSubmitting] = useState(false);

  // для рендера ошибок с сервера
  const [serverErrors, setServerErrors] = useState<ServerErrors | null>(null);
  const normalizedErrors = useMemo(() => {
    if (!serverErrors) return [];

    // превращаем всё в массив пар [field, message]
    // поддерживаем разные форматы
    if (typeof serverErrors === 'string') {
      return [['error', serverErrors] as const];
    }

    if ('error' in (serverErrors as any) || 'errors' in (serverErrors as any)) {
      const se = serverErrors as any;
      const out: Array<[string, string]> = [];
      if (se.error && typeof se.error === 'string') {
        out.push(['error', se.error]);
      }
      if (se.errors && typeof se.errors === 'object') {
        Object.entries(se.errors).forEach(([field, val]) => {
          if (Array.isArray(val)) {
            out.push([field, val.join(', ')]);
          } else if (val && typeof val === 'object') {
            // вложенные
            Object.entries(val as Record<string, any>).forEach(([k, v]) => {
              out.push([`${field}.${k}`, Array.isArray(v) ? v.join(', ') : String(v)]);
            });
          } else if (val != null) {
            out.push([field, String(val)]);
          }
        });
      }
      return out;
    }

    // обычный map {field: [..] | '...'}
    const out: Array<[string, string]> = [];
    Object.entries(serverErrors).forEach(([field, val]) => {
      if (Array.isArray(val)) out.push([field, val.join(', ')]);
      else if (val != null) out.push([field, String(val)]);
    });
    return out;
  }, [serverErrors]);

  function parseTags(input: string): string[] | undefined {
    const arr = input
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    return arr.length ? arr : undefined;
  }

  function toNumberOrNull(s: string): number | null {
    if (!s || !s.trim()) return null;
    const n = Number(s.replace(',', '.'));
    return Number.isFinite(n) ? n : null;
    }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setServerErrors(null);

    // простая валидация на клиенте — подсветим быстрее
    if (!title.trim() || !description.trim() || !location.trim()) {
      setServerErrors({
        title: !title.trim() ? ['can\'t be blank'] : [],
        description:
          !description.trim() ? ['can\'t be blank'] : (description.trim().length < 10 ? ['should be at least 10 character(s)'] : []),
        location: !location.trim() ? ['can\'t be blank'] : [],
      });
      return;
    }

    const price = toNumberOrNull(priceInput);
    const payload: PostPayload = {
      title: title.trim(),
      description: description.trim(),
      category,
      post_type: 'offer', // фиксированно
      location: location.trim(),
      urgency,
      tags: parseTags(tagsInput),
      price,                                  // null если пусто
      currency: price === null ? null : currency,
      skills_required: skillsRequired.trim() || null,
      duration_estimate: toNumberOrNull(durationEstimate),
      max_distance_km: toNumberOrNull(maxDistanceKm),
    };

    setSubmitting(true);
    try {
      await createPost(payload);
      // успех -> на главную
      router.push('/');
    } catch (err: any) {
      setServerErrors(err ?? 'Validation failed');
    } finally {
      setSubmitting(false);
    }
  }

  /** ==== UI (оставьте ваши className, я не менял дизайн-смысл) ==== */
  return (
    <div className="mx-auto max-w-2xl p-4">
      <h1 className="text-xl font-semibold mb-4">Создать пост</h1>

      {/* Ошибки сервера */}
      {normalizedErrors.length > 0 && (
        <div className="mb-4 rounded border border-red-200 bg-red-50 p-3 text-red-700 text-sm">
          <div className="font-medium mb-1">Ошибка валидации</div>
          <ul className="list-disc list-inside space-y-1">
            {normalizedErrors.map(([field, msg]) => (
              <li key={`${field}-${msg}`}>
                <strong>{field}:</strong> {msg}
              </li>
            ))}
          </ul>
        </div>
      )}

      <form onSubmit={onSubmit} className="space-y-4">
        {/* Заголовок */}
        <div>
          <label className="block text-sm mb-1">Заголовок</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Краткое название объявления"
            className="w-full rounded border px-3 py-2"
          />
        </div>

        {/* Описание */}
        <div>
          <label className="block text-sm mb-1">Описание</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={4}
            placeholder="Подробности (минимум 10 символов)"
            className="w-full rounded border px-3 py-2"
          />
        </div>

        {/* Категория (только 2 варианта) */}
        <div>
          <label className="block text-sm mb-1">Категория</label>
          <div className="flex gap-3">
            {CATEGORY_OPTIONS.map((opt) => (
              <label key={opt.value} className="inline-flex items-center gap-2">
                <input
                  type="radio"
                  name="category"
                  checked={category === opt.value}
                  onChange={() => setCategory(opt.value)}
                />
                <span>{opt.label}</span>
              </label>
            ))}
          </div>
        </div>

        {/* Срочность */}
        <div>
          <label className="block text-sm mb-1">Срочность</label>
          <select
            value={urgency}
            onChange={(e) => setUrgency(e.target.value as Urgency)}
            className="w-full rounded border px-3 py-2"
          >
            {URGENCY_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </div>

        {/* Локация (обязательная) */}
        <div>
          <label className="block text-sm mb-1">Локация</label>
          <input
            type="text"
            value={location}
            onChange={(e) => setLocation(e.target.value)}
            placeholder="Например: Ташкент, Юнус-Абад"
            className="w-full rounded border px-3 py-2"
          />
        </div>

        {/* Навыки (опционально) */}
        <div>
          <label className="block text-sm mb-1">Требуемые навыки (опционально)</label>
          <textarea
            value={skillsRequired}
            onChange={(e) => setSkillsRequired(e.target.value)}
            rows={2}
            placeholder="Например: Python, монтаж, грузоперевозки…"
            className="w-full rounded border px-3 py-2"
          />
        </div>

        {/* Длительность и радиус (опционально) */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div>
            <label className="block text-sm mb-1">Оценка длительности (часы)</label>
            <input
              type="number"
              min="0"
              step="0.5"
              value={durationEstimate}
              onChange={(e) => setDurationEstimate(e.target.value)}
              placeholder="Например: 2"
              className="w-full rounded border px-3 py-2"
            />
          </div>
          <div>
            <label className="block text-sm mb-1">Макс. расстояние (км)</label>
            <input
              type="number"
              min="0"
              step="1"
              value={maxDistanceKm}
              onChange={(e) => setMaxDistanceKm(e.target.value)}
              placeholder="Например: 10"
              className="w-full rounded border px-3 py-2"
            />
          </div>
        </div>

        {/* Цена (опционально) и Валюта */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div>
            <label className="block text-sm mb-1">Цена (опционально)</label>
            <input
              type="number"
              min="0"
              step="0.01"
              value={priceInput}
              onChange={(e) => setPriceInput(e.target.value)}
              placeholder="Оставьте пустым для «договорная»"
              className="w-full rounded border px-3 py-2"
            />
          </div>
          <div>
            <label className="block text-sm mb-1">Валюта</label>
            <select
              value={currency}
              onChange={(e) => setCurrency(e.target.value as Currency)}
              className="w-full rounded border px-3 py-2"
              disabled={!priceInput} // если цены нет — валюта неактивна
            >
              {CURRENCY_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Теги (опционально) */}
        <div>
          <label className="block text-sm mb-1">Теги (через запятую, опционально)</label>
          <input
            type="text"
            value={tagsInput}
            onChange={(e) => setTagsInput(e.target.value)}
            placeholder="напр.: ремонт, перевозка"
            className="w-full rounded border px-3 py-2"
          />
        </div>

        {/* post_type скрыт и всегда offer — по требованию */}
        <input type="hidden" name="post_type" value="offer" />

        <div className="pt-2">
          <button
            type="submit"
            disabled={submitting}
            className="rounded px-4 py-2 bg-blue-600 text-white disabled:opacity-50"
          >
            {submitting ? 'Создаём…' : 'Создать пост'}
          </button>
        </div>
      </form>
    </div>
  );
}
