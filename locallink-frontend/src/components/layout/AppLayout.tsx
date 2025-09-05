'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Home,
  Map as MapIcon,
  MessageCircle,
  PlusCircle,
  UserRound,
  Search,
} from 'lucide-react';

type Props = {
  children: React.ReactNode;
};

function BottomDock() {
  const pathname = usePathname();
  const item = (href: string, label: string, Icon: any) => {
    const active = pathname === href;
    return (
      <Link
        href={href}
        className={`flex flex-col items-center justify-center gap-1 flex-1 py-2 ${
          active ? 'text-black' : 'text-gray-500'
        }`}
      >
        <Icon className="h-5 w-5" />
        <span className="text-[11px]">{label}</span>
      </Link>
    );
  };

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 border-t bg-white/90 backdrop-blur supports-[backdrop-filter]:bg-white/60 md:bottom-4 md:left-1/2 md:-translate-x-1/2 md:w-[560px] md:rounded-2xl md:shadow-lg">
      <div className="flex px-4">
        {item('/', 'Главная', Home)}
        {item('/map', 'Карта', MapIcon)}
        {item('/create-post', 'Создать', PlusCircle)}
        {item('/messages', 'Чаты', MessageCircle)}
        {item('/profile', 'Профиль', UserRound)}
      </div>
    </nav>
  );
}

function TopBar() {
  return (
    <header className="fixed top-0 left-0 right-0 z-40 border-b bg-white/90 backdrop-blur supports-[backdrop-filter]:bg-white/60">
      <div className="mx-auto max-w-7xl px-4 py-3 flex items-center gap-3">
        <Link href="/" className="font-semibold text-lg tracking-tight">
          LocalLink
        </Link>

        {/* Кнопка “Фильтры” как в макете — просто заглушка, сами фильтры уже есть на главной */}
        <Link
          href="/"
          className="ml-auto inline-flex items-center gap-2 rounded-2xl border px-3 h-10 text-sm text-gray-700 hover:bg-gray-50"
        >
          <Search className="h-4 w-4" />
          Фильтры
        </Link>

        {/* Кнопки входа/регистрации в шапке */}
        <Link
          href="/login"
          className="hidden sm:inline-flex items-center rounded-2xl border h-10 px-4 ml-2 hover:bg-gray-50"
        >
          Войти
        </Link>
        <Link
          href="/register"
          className="hidden sm:inline-flex items-center rounded-2xl bg-black text-white h-10 px-4 ml-1 hover:opacity-90"
        >
          Регистрация
        </Link>
      </div>
    </header>
  );
}

export default function AppLayout({ children }: Props) {
  return (
    <div className="min-h-dvh bg-gray-50">
      <TopBar />
      <main className="mx-auto max-w-7xl px-4 pt-[64px] pb-[76px] md:pb-[96px]">
        {children}
      </main>
      <BottomDock />
    </div>
  );
}
