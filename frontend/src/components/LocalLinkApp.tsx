import React, { useState, useEffect } from 'react';
import {
  Search,
  Plus,
  Filter,
  Menu,
  User as UserIcon,
  LogOut
} from 'lucide-react';
import PostCard from './ui/PostCard';
import LoginForm from './ui/LoginForm';
import RegisterForm from './ui/RegisterForm';
import CreatePostForm from './ui/CreatePostForm';
import { Post, AppUser } from './api';

const API_BASE_URL = "http://localhost:4000/api/v1";

const LocalLinkApp = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentUser, setCurrentUser] = useState<AppUser | null>(null);
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [authMode, setAuthMode] = useState('login');
  const [showCreatePost, setShowCreatePost] = useState(false);
  const [showMobileMenu, setShowMobileMenu] = useState(false);
  const [activeTab, setActiveTab] = useState('all');
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const checkJsonResponse = async (response: Response, requestInfo: string) => {
    const contentType = response.headers.get('content-type');
    console.log(`[${requestInfo}] Status: ${response.status}, Content-Type: ${contentType}`);

    if (!contentType || !contentType.includes('application/json')) {
      // Логируем содержимое ответа для отладки
      const responseText = await response.text();
      console.error(`[${requestInfo}] Unexpected response:`, responseText.substring(0, 500));

      throw new Error(`Эндпоинт ${requestInfo} вернул ${contentType || 'неизвестный тип'} вместо JSON. Возможно, проблема с авторизацией или конфигурацией сервера.`);
    }
  };

  const fetchPosts = async () => {
    try {
      setLoading(true);
      setError(null);

      const res = await fetch(`${API_BASE_URL}/posts`, {
        headers: {
          'Accept': 'application/json'
        }
      });

      await checkJsonResponse(res, 'GET /posts');
      const data = await res.json();

      if (res.ok) {
        setPosts(data.posts || []);
      } else {
        console.error("Ошибка ответа от API:", res.status, data);
        setError(data.error || `Ошибка загрузки постов: ${res.status}`);
      }
    } catch (error) {
      console.error("Ошибка запроса к API:", error);
      let errorMessage = 'Ошибка подключения к серверу';

      if (error instanceof Error) {
        if (error.message.includes('fetch')) {
          errorMessage = 'Не удается подключиться к серверу. Убедитесь, что сервер запущен на http://localhost:4000';
        } else {
          errorMessage = error.message;
        }
      }

      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const fetchCurrentUser = async (token: string) => {
    try {
      console.log(`Проверяем токен: ${token.substring(0, 20)}...`);

      const res = await fetch(`${API_BASE_URL}/me`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Accept': 'application/json'
        }
      });

      console.log(`Ответ /me: Status ${res.status}, Headers:`, Object.fromEntries(res.headers.entries()));

      // Проверяем ответ без автоматической обработки JSON
      const contentType = res.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        const responseText = await res.text();
        console.error('Неожиданный ответ от /me:', responseText.substring(0, 500));

        // Если токен невалиден, удаляем его и просим войти заново
        if (res.status === 401 || res.status === 403) {
          localStorage.removeItem('token');
          setError('Сессия истекла. Войдите заново.');
          return;
        }

        throw new Error(`Эндпоинт /me вернул ${contentType} вместо JSON. Возможно, проблема с конфигурацией auth pipeline.`);
      }

      const data = await res.json();

      if (res.ok) {
        setCurrentUser(data.user);
        setIsAuthenticated(true);
        console.log('Пользователь успешно загружен:', data.user.first_name);
      } else {
        console.error('Ошибка авторизации:', data);
        localStorage.removeItem('token');
        setError(data.error || 'Ошибка проверки авторизации');
      }
    } catch (err) {
      console.error('Ошибка загрузки пользователя:', err);
      localStorage.removeItem('token');
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Ошибка проверки авторизации');
      }
    }
  };

  useEffect(() => {
    fetchPosts();

    const token = localStorage.getItem('token');
    if (token) {
      fetchCurrentUser(token);
    }
  }, []);

  const openAuthModal = (mode = 'login') => {
    setAuthMode(mode);
    setShowAuthModal(true);
    setError(null);
  };

  const closeAuthModal = () => {
    setShowAuthModal(false);
  };

  const handleLoginSuccess = (token: string, user: AppUser) => {
    setIsAuthenticated(true);
    setCurrentUser(user);
    setError(null);
    localStorage.setItem('token', token);
  };

  const handleRegisterSuccess = (token: string, user: AppUser) => {
    setIsAuthenticated(true);
    setCurrentUser(user);
    setError(null);
    localStorage.setItem('token', token);
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    setCurrentUser(null);
    setError(null);
    localStorage.removeItem('token');
  };

  const handlePostCreated = () => {
    fetchPosts();
  };

  const filteredPosts = posts.filter(post => {
    if (activeTab === 'all') return true;
    return post.category === activeTab;
  });

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-6xl mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <h1 className="text-xl font-bold text-blue-600">LocalLink</h1>
              <span className="text-sm text-gray-500 hidden sm:block">Соединяем соседей</span>
            </div>

            <div className="hidden md:flex items-center space-x-4">
              {isAuthenticated ? (
                <>
                  <button
                    onClick={() => setShowCreatePost(true)}
                    className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center space-x-2"
                  >
                    <Plus size={16} />
                    <span>Создать</span>
                  </button>
                  <div className="flex items-center space-x-2">
                    <div className="w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center">
                      <UserIcon size={16} />
                    </div>
                    <span className="text-sm font-medium">
                      {currentUser?.first_name} {currentUser?.last_name}
                    </span>
                    <button
                      onClick={handleLogout}
                      className="text-gray-500 hover:text-red-600"
                    >
                      <LogOut size={16} />
                    </button>
                  </div>
                </>
              ) : (
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => openAuthModal('login')}
                    className="text-gray-600 hover:text-blue-600 px-3 py-2"
                  >
                    Войти
                  </button>
                  <button
                    onClick={() => openAuthModal('register')}
                    className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
                  >
                    Регистрация
                  </button>
                </div>
              )}
            </div>

            <button
              onClick={() => setShowMobileMenu(!showMobileMenu)}
              className="md:hidden text-gray-600 hover:text-blue-600"
            >
              <Menu size={20} />
            </button>
          </div>

          {showMobileMenu && (
            <div className="md:hidden mt-4 pt-4 border-t">
              {isAuthenticated ? (
                <div className="space-y-2">
                  <button
                    onClick={() => {
                      setShowCreatePost(true);
                      setShowMobileMenu(false);
                    }}
                    className="w-full bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center justify-center space-x-2"
                  >
                    <Plus size={16} />
                    <span>Создать объявление</span>
                  </button>
                  <div className="flex items-center justify-between pt-2">
                    <span className="text-sm font-medium">
                      {currentUser?.first_name} {currentUser?.last_name}
                    </span>
                    <button
                      onClick={handleLogout}
                      className="text-red-600 hover:text-red-700"
                    >
                      Выйти
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-2">
                  <button
                    onClick={() => {
                      openAuthModal('login');
                      setShowMobileMenu(false);
                    }}
                    className="w-full text-center py-2 text-gray-600 hover:text-blue-600"
                  >
                    Войти
                  </button>
                  <button
                    onClick={() => {
                      openAuthModal('register');
                      setShowMobileMenu(false);
                    }}
                    className="w-full bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
                  >
                    Регистрация
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </header>

      {error && (
        <div className="max-w-6xl mx-auto px-4 py-2">
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
            <div className="flex justify-between items-center">
              <span>{error}</span>
              <button
                onClick={() => setError(null)}
                className="text-red-500 hover:text-red-700"
              >
                ×
              </button>
            </div>
          </div>
        </div>
      )}

      <main className="max-w-6xl mx-auto px-4 py-6">
        <div className="bg-white rounded-lg shadow-sm p-4 mb-6">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
              <input
                type="text"
                placeholder="Поиск объявлений..."
                className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <button className="px-4 py-2 border rounded-lg hover:bg-gray-50 flex items-center space-x-2">
              <Filter size={16} />
              <span>Фильтры</span>
            </button>
          </div>

          <div className="flex space-x-1 mt-4 overflow-x-auto">
            {[
              { key: 'all', label: 'Все', icon: '📋' },
              { key: 'task', label: 'Задачи', icon: '🛠️' },
              { key: 'job', label: 'Работа', icon: '💼' },
              { key: 'social', label: 'Социальное', icon: '🎉' },
              { key: 'help_needed', label: 'Помощь', icon: '🆘' }
            ].map(tab => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`px-4 py-2 rounded-lg whitespace-nowrap flex items-center space-x-2 ${
                  activeTab === tab.key
                    ? 'bg-blue-100 text-blue-600 border-blue-200'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <span>{tab.icon}</span>
                <span>{tab.label}</span>
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="text-center py-12">
            <div className="text-4xl mb-4">⏳</div>
            <p className="text-gray-500">Загрузка объявлений...</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredPosts.map(post => (
              <PostCard key={post.id} post={post} />
            ))}
          </div>
        )}

        {!loading && filteredPosts.length === 0 && !error && (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">📭</div>
            <h3 className="text-lg font-medium text-gray-600 mb-2">
              Объявлений не найдено
            </h3>
            <p className="text-gray-500">
              Попробуйте изменить фильтры или создайте первое объявление
            </p>
            {!isAuthenticated && (
              <button
                onClick={() => openAuthModal('login')}
                className="mt-4 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
              >
                Войти для создания объявления
              </button>
            )}
          </div>
        )}
      </main>

      {showAuthModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          {authMode === 'login' ? (
            <LoginForm
              onClose={closeAuthModal}
              onSwitchToRegister={() => setAuthMode('register')}
              onLoginSuccess={handleLoginSuccess}
            />
          ) : (
            <RegisterForm
              onClose={closeAuthModal}
              onSwitchToLogin={() => setAuthMode('login')}
              onRegisterSuccess={handleRegisterSuccess}
            />
          )}
        </div>
      )}

      {showCreatePost && isAuthenticated && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <CreatePostForm
            onClose={() => setShowCreatePost(false)}
            onPostCreated={handlePostCreated}
          />
        </div>
      )}
    </div>
  );
};

export default LocalLinkApp;
