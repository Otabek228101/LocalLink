import React, { useState } from 'react';

interface Props {
  onClose: () => void;
  onPostCreated: () => void;
}

const CreatePostForm: React.FC<Props> = ({ onClose, onPostCreated }) => {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: 'task',
    post_type: 'seeking',
    location: '',
    urgency: 'flexible',
    price: '',
    currency: 'UZS',
    skills_required: '',
  });

  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const token = localStorage.getItem('token');
      if (!token) {
        setError('Необходимо войти в систему');
        setIsLoading(false);
        return;
      }

      // Подготавливаем данные для отправки
      const postData = {
        title: formData.title.trim(),
        description: formData.description.trim(),
        category: formData.category,
        post_type: formData.post_type,
        location: formData.location.trim(),
        urgency: formData.urgency,
        price: formData.price ? parseFloat(formData.price) : null,
        currency: formData.currency,
        skills_required: formData.skills_required.trim(), // Отправляем как строку
      };

      console.log('Отправляем данные:', postData);

      const response = await fetch("http://localhost:4000/api/v1/posts", {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          post: postData
        })
      });

      // Проверяем, что ответ действительно JSON
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        throw new Error('Сервер вернул некорректный ответ. Проверьте авторизацию и настройки API.');
      }

      const data = await response.json();
      console.log('Ответ сервера:', data);

      if (response.ok) {
        onPostCreated();
        onClose();
      } else {
        const errorMsg = data.errors ?
          Object.entries(data.errors).map(([key, value]) => `${key}: ${Array.isArray(value) ? value.join(', ') : value}`).join('; ')
          : data.error || `Ошибка сервера: ${response.status}`;
        setError(errorMsg);
      }
    } catch (err) {
      console.error('Ошибка при создании поста:', err);

      let errorMessage = 'Ошибка подключения к серверу';
      if (err instanceof Error) {
        if (err.message.includes('fetch')) {
          errorMessage = 'Не удается подключиться к серверу. Проверьте, что сервер запущен.';
        } else if (err.message.includes('JSON')) {
          errorMessage = 'Ошибка обработки ответа сервера. Возможно, проблема с авторизацией.';
        } else {
          errorMessage = err.message;
        }
      }

      setError(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-lg max-w-md w-full p-6 relative">
      <button
        onClick={onClose}
        disabled={isLoading}
        className="absolute top-2 right-2 text-gray-500 hover:text-red-600 text-xl disabled:opacity-50"
      >
        &times;
      </button>
      <h2 className="text-xl font-bold mb-4">Создать объявление</h2>

      {error && <p className="text-red-600 mb-3 text-sm">{error}</p>}

      <form onSubmit={handleSubmit} className="space-y-4">
        <input
          type="text"
          name="title"
          placeholder="Заголовок"
          value={formData.title}
          onChange={handleChange}
          required
          disabled={isLoading}
          className="w-full border px-4 py-2 rounded-lg disabled:opacity-50"
        />

        <textarea
          name="description"
          placeholder="Описание"
          value={formData.description}
          onChange={handleChange}
          required
          disabled={isLoading}
          rows={3}
          className="w-full border px-4 py-2 rounded-lg disabled:opacity-50"
        />

        <select
          name="category"
          value={formData.category}
          onChange={handleChange}
          disabled={isLoading}
          className="w-full border px-4 py-2 rounded-lg disabled:opacity-50"
        >
          <option value="task">Задача</option>
          <option value="job">Работа</option>
          <option value="event">Событие</option>
          <option value="help_needed">Нужна помощь</option>
        </select>

        <select
          name="post_type"
          value={formData.post_type}
          onChange={handleChange}
          disabled={isLoading}
          className="w-full border px-4 py-2 rounded-lg disabled:opacity-50"
        >
          <option value="seeking">Нужна помощь</option>
          <option value="offer">Предлагаю помощь</option>
        </select>

        <input
          type="text"
          name="location"
          placeholder="Локация"
          value={formData.location}
          onChange={handleChange}
          required
          disabled={isLoading}
          className="w-full border px-4 py-2 rounded-lg disabled:opacity-50"
        />

        <select
          name="urgency"
          value={formData.urgency}
          onChange={handleChange}
          disabled={isLoading}
          className="w-full border px-4 py-2 rounded-lg disabled:opacity-50"
        >
          <option value="flexible">Гибкий график</option>
          <option value="this_week">На этой неделе</option>
          <option value="tomorrow">Завтра</option>
          <option value="today">Сегодня</option>
          <option value="now">Срочно</option>
        </select>

        <input
          type="text"
          name="skills_required"
          placeholder="Необходимые навыки (через запятую)"
          value={formData.skills_required}
          onChange={handleChange}
          disabled={isLoading}
          className="w-full border px-4 py-2 rounded-lg disabled:opacity-50"
        />

        <div className="flex space-x-2">
          <input
            type="number"
            name="price"
            placeholder="Цена"
            value={formData.price}
            onChange={handleChange}
            disabled={isLoading}
            min="0"
            step="0.01"
            className="flex-1 border px-4 py-2 rounded-lg disabled:opacity-50"
          />
          <select
            name="currency"
            value={formData.currency}
            onChange={handleChange}
            disabled={isLoading}
            className="border px-2 py-2 rounded-lg disabled:opacity-50"
          >
            <option value="UZS">UZS</option>
            <option value="USD">$</option>
            <option value="EUR">€</option>
            <option value="RUB">₽</option>
          </select>
        </div>

        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isLoading ? 'Создание...' : 'Создать'}
        </button>
      </form>
    </div>
  );
};

export default CreatePostForm;
