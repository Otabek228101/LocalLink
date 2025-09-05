'use client';

import { useEffect, useState } from 'react';
import api, { type User } from '../../services/api';

export default function ProfilePage() {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const { user } = await api.getProfile();
        setUser(user);
      } catch {
        // игнорируем, чтобы страница не падала
      }
    })();
  }, []);

  return (
    <div className="max-w-6xl mx-auto p-4">
      <h1 className="text-xl font-semibold mb-4">Профиль</h1>

      {!user ? (
        <div className="rounded-2xl border bg-white p-6 text-gray-500">
          Загрузка профиля…
        </div>
      ) : (
        <div className="rounded-2xl border bg-white p-6 grid gap-4">
          <div className="text-lg font-medium">
            {user.first_name ?? ''} {user.last_name ?? ''}
          </div>
          <div className="text-gray-600">{user.email}</div>
          {user.phone && <div className="text-gray-600">{user.phone}</div>}
          {user.location && <div className="text-gray-600">{user.location}</div>}
        </div>
      )}
    </div>
  );
}
