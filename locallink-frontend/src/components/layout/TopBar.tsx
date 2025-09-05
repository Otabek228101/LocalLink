'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import api from '../../services/api';
import type { User } from '../../services/api';

export default function TopBar() {
  const [user, setUser] = useState<User | null>(null);
  const [q, setQ] = useState('');

  // загружаем профиль, если есть токен
  const loadUser = () => {
    const token = api.getToken();
    if (!token) {
      setUser(null);
      return;
    }
    api
      .getProfile()
      .then((u) => setUser(u.user ?? u)) // поддержка {user:{...}} и просто {...}
      .catch(() => setUser(null));
  };

  useEffect(() => {
    loadUser();
    // реагируем на смену токена из любого места приложения
    const onAuth = () => loadUser();
    window.addEventListener('auth-changed', onAuth);
    return () => window.removeEventListener('auth-changed', onAuth);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const logout = () => {
    api.removeToken();
    setUser(null);
  };

  return (
    <header className="sticky top-0 z-40 w-full border-b bg-white/80 backdrop-blur">
      <div className="mx-auto max-w-7xl px-4 py-3 flex items-center gap-4">
        {/* Лого */}
        <Link href="/" className="flex items-center gap-2 select-none">
          <span className="grid h-8 w-8 place-items-center rounded-xl bg-blue-600 text-white font-bold">
            L
          </span>
          <span className="text-lg font-semibold">LocalLink</span>
        </Link>

        {/* Поиск центр */}
        <div className="mx-auto w-full max-w-2xl">
          <div className="flex h-10 items-center gap-2 rounded-2xl border bg-slate-50 px-3">
            <span className="i-lucide-search h-4 w-4 opacity-60" />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search…"
              className="h-10 w-full bg-transparent outline-none"
            />
          </div>
        </div>

        {/* Справа: либо кнопки, либо профиль */}
        {user ? (
          <div className="flex items-center gap-3">
            <Link
              href="/profile"
              className="rounded-full bg-blue-50 text-blue-700 px-4 h-9 flex items-center font-medium"
              title="Профиль"
            >
              {user.first_name ?? user.email}
            </Link>
            <button
              onClick={logout}
              className="rounded-2xl border px-4 h-9 hover:bg-slate-50"
            >
              Выйти
            </button>
          </div>
        ) : (
          <div className="flex items-center gap-3">
            <Link
              href="/login"
              className="rounded-2xl bg-blue-50 text-blue-700 px-4 h-9 flex items-center font-medium"
            >
              Войти
            </Link>
            <Link
              href="/register"
              className="rounded-2xl bg-blue-50 text-blue-700 px-4 h-9 flex items-center font-medium"
            >
              Регистрация
            </Link>
          </div>
        )}
      </div>
    </header>
  );
}
