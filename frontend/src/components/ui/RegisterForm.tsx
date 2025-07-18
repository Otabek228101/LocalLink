import React, { useState, ChangeEvent, FormEvent } from 'react';
import { X } from 'lucide-react';
import { AppUser } from '../api';

interface RegisterFormProps {
  onClose: () => void;
  onSwitchToLogin: () => void;
  onRegisterSuccess: (token: string, user: AppUser) => void;
}

interface FormData {
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  password: string;
  confirmPassword: string;
}

const RegisterForm = ({ onClose, onSwitchToLogin, onRegisterSuccess }: RegisterFormProps) => {
  const [formData, setFormData] = useState<FormData>({
    first_name: '',
    last_name: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: ''
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    if (formData.password !== formData.confirmPassword) {
      setError('Пароли не совпадают');
      return;
    }

    if (formData.password.length < 6) {
      setError('Пароль должен содержать минимум 6 символов');
      return;
    }

    setIsLoading(true);
    setError('');

    try {
      const response = await fetch("http://localhost:4000/api/v1/register", {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          user: {
            first_name: formData.first_name,
            last_name: formData.last_name,
            email: formData.email,
            phone: formData.phone,
            password: formData.password
          }
        })
      });

      // Проверяем, что ответ действительно JSON
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        throw new Error('Сервер вернул некорректный ответ. Проверьте, что API сервер запущен.');
      }

      const data = await response.json();

      if (!response.ok) {
        const errorMsg = data.errors ?
          Object.entries(data.errors).map(([key, value]) => `${key}: ${Array.isArray(value) ? value.join(', ') : value}`).join('; ')
          : data.error || `Ошибка регистрации: ${response.status}`;
        throw new Error(errorMsg);
      }

      if (!data.token || !data.user) {
        throw new Error('Некорректный ответ от сервера');
      }

      localStorage.setItem('token', data.token);
      onRegisterSuccess(data.token, data.user);
      onClose();
    } catch (error: unknown) {
      console.error('Registration error:', error);
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

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value
    }));
  };

  return (
    <div className="bg-white p-6 rounded-lg max-w-md w-full">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-bold">Регистрация</h2>
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
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Имя*</label>
            <input
              type="text"
              name="first_name"
              value={formData.first_name}
              onChange={handleChange}
              className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
              disabled={isLoading}
              minLength={2}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Фамилия*</label>
            <input
              type="text"
              name="last_name"
              value={formData.last_name}
              onChange={handleChange}
              className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
              disabled={isLoading}
              minLength={2}
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Email*</label>
          <input
            type="email"
            name="email"
            value={formData.email}
            onChange={handleChange}
            className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
            disabled={isLoading}
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Телефон</label>
          <input
            type="tel"
            name="phone"
            value={formData.phone}
            onChange={handleChange}
            placeholder="+998901234567"
            className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={isLoading}
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Пароль* (минимум 6 символов)</label>
          <input
            type="password"
            name="password"
            value={formData.password}
            onChange={handleChange}
            className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
            disabled={isLoading}
            minLength={6}
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Подтвердите пароль*</label>
          <input
            type="password"
            name="confirmPassword"
            value={formData.confirmPassword}
            onChange={handleChange}
            className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
            disabled={isLoading}
            minLength={6}
          />
        </div>

        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isLoading ? 'Регистрация...' : 'Зарегистрироваться'}
        </button>
      </form>

      <p className="text-center mt-4 text-sm">
        Уже есть аккаунт?{' '}
        <button
          onClick={onSwitchToLogin}
          className="text-blue-600 hover:underline"
          disabled={isLoading}
        >
          Войти
        </button>
      </p>
    </div>
  );
};

export default RegisterForm;
