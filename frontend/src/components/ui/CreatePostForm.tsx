import React, { useState, ChangeEvent, FormEvent } from 'react';
import { X } from 'lucide-react';

interface CreatePostFormProps {
  onClose: () => void;
  onPostCreated: () => void;
}

interface PostFormData {
  title: string;
  description: string;
  category: string;
  post_type: string;
  urgency: string;
  price: string;
  location: string;
  skills_required: string[];
}

const CreatePostForm = ({ onClose, onPostCreated }: CreatePostFormProps) => {
  const [formData, setFormData] = useState<PostFormData>({
    title: '',
    description: '',
    category: 'task',
    post_type: 'seeking',
    urgency: 'flexible',
    price: '',
    location: 'Ташкент, Узбекистан',
    skills_required: []
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    
    const token = localStorage.getItem('token');
    if (!token) {
      setError('Требуется авторизация');
      return;
    }
    
    setIsLoading(true);
    setError('');
    
    try {
      const response = await fetch('http://localhost:4000/api/posts', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ 
          post: {
            ...formData,
            price: formData.price ? parseFloat(formData.price) : null,
            currency: 'UZS'
          }
        })
      });
      
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.errors || 'Ошибка создания поста');
      }
      
      onPostCreated();
      onClose();
    } catch (error: unknown) {
      let errorMessage = 'Неизвестная ошибка';
      if (error instanceof Error) {
        errorMessage = error.message;
      }
      setError(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  const handleChange = (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    
    setFormData(prev => ({
      ...prev,
      [name]: name === 'post_type' 
        ? (value === 'request' ? 'seeking' : 'offer')
        : value
    }));
  };

  return (
    <div className="bg-white p-6 rounded-lg max-w-md w-full max-h-[90vh] overflow-y-auto">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-bold">Создать объявление</h2>
        <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
          <X size={20} />
        </button>
      </div>
      
      {error && <div className="text-red-500 mb-4 text-sm">{error}</div>}
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">Заголовок</label>
          <input
            type="text"
            name="title"
            value={formData.title}
            onChange={handleChange}
            className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
          />
        </div>
        
        <div>
          <label className="block text-sm font-medium mb-1">Описание</label>
          <textarea
            name="description"
            value={formData.description}
            onChange={handleChange}
            rows={3}
            className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
          />
        </div>
        
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Категория</label>
            <select
              name="category"
              value={formData.category}
              onChange={handleChange}
              className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="task">Задача</option>
              <option value="job">Работа</option>
              <option value="social">Социальное</option>
              <option value="event">Событие</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">Тип</label>
            <select
              name="post_type"
              value={formData.post_type === 'seeking' ? 'request' : 'offer'}
              onChange={handleChange}
              className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="request">Нужна помощь</option>
              <option value="offer">Предлагаю</option>
            </select>
          </div>
        </div>
        
        <div>
          <label className="block text-sm font-medium mb-1">Срочность</label>
            <select
              name="urgency"
              value={formData.urgency}
              onChange={handleChange}
              className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="now">Срочно</option>
              <option value="today">Сегодня</option>
              <option value="tomorrow">Завтра</option>
              <option value="this_week">На этой неделе</option>
              <option value="flexible">Гибкий график</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">Цена (необязательно)</label>
            <input
              type="number"
              name="price"
              value={formData.price}
              onChange={handleChange}
              placeholder="Например: 50000"
              className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-1">Локация</label>
            <input
              type="text"
              name="location"
              value={formData.location}
              onChange={handleChange}
              className="w-full p-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          
          <button
            type="submit"
            disabled={isLoading}
            className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            {isLoading ? 'Создание...' : 'Создать объявление'}
          </button>
        </form>
      </div>
    );
};

export default CreatePostForm;