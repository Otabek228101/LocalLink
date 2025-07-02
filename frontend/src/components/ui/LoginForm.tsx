import React, { useState, ChangeEvent, FormEvent } from 'react';
import { X } from 'lucide-react';
import { AppUser } from '../api';

interface LoginFormProps {
  onClose: () => void;
  onSwitchToRegister: () => void;
  onLoginSuccess: (token: string, user: AppUser) => void;
}

const LoginForm = ({ onClose, onSwitchToRegister, onLoginSuccess }: LoginFormProps) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const response = await fetch('http://localhost:4000/api/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ email, password })
      });

      // Проверяем, что ответ действительно JSON
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        throw new Error('Сервер вернул некорректный ответ. Проверьте, что API сервер запущен.');
      }

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || `Ошибка сервера: ${response.status}`);
      }

      if (!data.token || !data.user) {
        throw new Error('Некорректный ответ от сервера');
      }

      localStorage.setItem('token', data.token);
      onLoginSuccess(data.token, data.user);
      onClose();
    } catch (error: unknown) {
      console.error('Login error:', error);
      let errorMessage = 'Неизвестная ошибка';

      if (error instanceof Error) {
        if (error.message.includes('fetch')) {
          errorMessage = 'Не удается подключиться к серверу. Проверьте, что сервер запущен на порту 4000.';
        } else if (error.message.includes('JSON')) {
          errorMessage = 'Ошибка обработки ответа сервера. Проверьте настройки API.';
        } else {
          errorMessage = error.message;
        }
      }

      setError(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="bg-white p-6 rounded-lg max-w-md w-full">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-bold">Вход</h2>
        <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
          <X size={20} />
        </button>
      </div>

      {error && (
        <div className="text-red-500 mb-4 text-sm bg-red-50 p-3 rounded">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">Email</label>
          <input
            type="email"
            value={email}
            onChange={(e: ChangeEvent<HTMLInputElement>) => setEmail(e.target.value)}
            className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
            disabled={isLoading}
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Пароль</label>
          <input
            type="password"
            value={password}
            onChange={(e: ChangeEvent<HTMLInputElement>) => setPassword(e.target.value)}
            className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
            disabled={isLoading}
          />
        </div>

        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isLoading ? 'Вход...' : 'Войти'}
        </button>
      </form>

      <p className="text-center mt-4 text-sm">
        Нет аккаунта?{' '}
        <button
          onClick={onSwitchToRegister}
          className="text-blue-600 hover:underline"
          disabled={isLoading}
        >
          Зарегистрироваться
        </button>
      </p>

      <div className="mt-4 text-xs text-gray-500 bg-gray-50 p-2 rounded">
        <strong>Тестовые аккаунты:</strong><br/>
        alice@example.com / password123<br/>
        bob@example.com / password123
      </div>
    </div>
  );
};

export default LoginForm;
