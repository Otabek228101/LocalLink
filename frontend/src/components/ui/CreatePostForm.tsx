import React, { useState } from 'react';
import { 
    X,
  } from 'lucide-react';
const CreatePostForm = ({ onClose }) => {
    const [formData, setFormData] = useState({
      title: '',
      description: '',
      category: 'task',
      type: 'request',
      urgency: 'flexible',
      price: '',
      location: { address: 'Ташкент, Узбекистан' },
      skills_required: []
    });
  
    const handleSubmit = (e) => {
      e.preventDefault();   
      console.log('Creating post:', formData);
      onClose();
    };
  
    const handleChange = (e) => {
      const { name, value } = e.target;
      setFormData(prev => ({
        ...prev,
        [name]: value
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
                name="type"
                value={formData.type}
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
          
          <button
            type="submit"
            className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700"
          >
            Создать объявление
          </button>
        </form>
      </div>
    );
};

export default CreatePostForm;