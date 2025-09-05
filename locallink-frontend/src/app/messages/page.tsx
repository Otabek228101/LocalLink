'use client';

import React from 'react';

export default function MessagesPage() {
  // API для диалогов пока не подключаем (getConversations у api нет),
  // поэтому показываем пустое состояние, чтобы страница компилировалась.
  return (
    <div className="max-w-6xl mx-auto p-4">
      <h1 className="text-xl font-semibold mb-4">Сообщения</h1>
      <div className="rounded-2xl border bg-white p-8 text-gray-500">
        У вас пока нет сообщений.
      </div>
    </div>
  );
}
