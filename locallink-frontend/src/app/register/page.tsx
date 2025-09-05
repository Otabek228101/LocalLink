'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import apiService, { RegisterRequest } from '../../services/api';

export default function RegisterPage() {
  const router = useRouter();
  const [form, setForm] = useState<RegisterRequest>({
    email: '',
    password: '',
    first_name: '',
    last_name: '',
    phone: '',
    location: '',
    skills: '',
    availability: '',
  });

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function onChange<K extends keyof RegisterRequest>(key: K, value: RegisterRequest[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    // быстрая проверка “всё заполнено”
    for (const [k, v] of Object.entries(form)) {
      if (typeof v === 'string' && v.trim() === '') {
        setError('Пожалуйста, заполните все поля.');
        return;
      }
    }

    try {
      setSubmitting(true);
      // ВАЖНО: сюда передаём ПЛОСКИЙ объект (RegisterRequest),
      // apiService САМ оборачивает в {"user": {...}} для бекенда
      const { token } = await apiService.register(form);
      apiService.saveToken(token);
      router.push('/');
    } catch (e: any) {
      setError(e?.message ?? 'Регистрация не удалась');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="mx-auto max-w-md py-6">
      <h1 className="text-xl font-semibold mb-4">Регистрация</h1>

      <form onSubmit={onSubmit} className="rounded-2xl border bg-white p-4 grid gap-3">
        {error && <div className="text-sm text-red-600">{error}</div>}

        <div className="grid gap-2">
          <label className="text-sm text-gray-600">Email</label>
          <input
            className="h-11 rounded-2xl border px-3 outline-none"
            type="email"
            value={form.email}
            onChange={(e) => onChange('email', e.target.value)}
            placeholder="worker@example.com"
          />
        </div>

        <div className="grid gap-2">
          <label className="text-sm text-gray-600">Пароль</label>
          <input
            className="h-11 rounded-2xl border px-3 outline-none"
            type="password"
            value={form.password}
            onChange={(e) => onChange('password', e.target.value)}
            placeholder="••••••••"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="grid gap-2">
            <label className="text-sm text-gray-600">Имя</label>
            <input
              className="h-11 rounded-2xl border px-3 outline-none"
              value={form.first_name}
              onChange={(e) => onChange('first_name', e.target.value)}
              placeholder="Дмитрий"
            />
          </div>
          <div className="grid gap-2">
            <label className="text-sm text-gray-600">Фамилия</label>
            <input
              className="h-11 rounded-2xl border px-3 outline-none"
              value={form.last_name}
              onChange={(e) => onChange('last_name', e.target.value)}
              placeholder="Петров"
            />
          </div>
        </div>

        <div className="grid gap-2">
          <label className="text-sm text-gray-600">Телефон</label>
          <input
            className="h-11 rounded-2xl border px-3 outline-none"
            value={form.phone}
            onChange={(e) => onChange('phone', e.target.value)}
            placeholder="+998907654321"
          />
        </div>

        <div className="grid gap-2">
          <label className="text-sm text-gray-600">Локация</label>
          <input
            className="h-11 rounded-2xl border px-3 outline-none"
            value={form.location}
            onChange={(e) => onChange('location', e.target.value)}
            placeholder="Ташкент, Юнус-Абад"
          />
        </div>

        <div className="grid gap-2">
          <label className="text-sm text-gray-600">Навыки</label>
          <input
            className="h-11 rounded-2xl border px-3 outline-none"
            value={form.skills}
            onChange={(e) => onChange('skills', e.target.value)}
            placeholder="Python, Django, JavaScript, React"
          />
        </div>

        <div className="grid gap-2">
          <label className="text-sm text-gray-600">Занятость</label>
          <input
            className="h-11 rounded-2xl border px-3 outline-none"
            value={form.availability}
            onChange={(e) => onChange('availability', e.target.value)}
            placeholder="Неполный день"
          />
        </div>

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={submitting}
            className="inline-flex items-center justify-center rounded-2xl bg-black text-white h-11 px-5 disabled:opacity-60"
          >
            {submitting ? 'Создаём…' : 'Зарегистрироваться'}
          </button>
        </div>
      </form>
    </div>
  );
}
