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

const API_BASE_URL = 'http://localhost:4000/api';

const LocalLinkApp = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [currentUser, setCurrentUser] = useState<AppUser | null>(null);
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [authMode, setAuthMode] = useState('login');
  const [showCreatePost, setShowCreatePost] = useState(false);
  const [showMobileMenu, setShowMobileMenu] = useState(false);
  const [activeTab, setActiveTab] = useState('all');
  const [posts, setPosts] = useState<Post[]>([]);
  const fetchPosts = async () => {
    try {
      const res = await fetch(`${API_BASE_URL}/posts`);
      const data = await res.json();
      if (res.ok) {
        setPosts(data.posts);
      } else {
        console.error(data.error || 'Failed to load posts');
      }
    } catch (err) {
      console.error('Failed to load posts', err);
    }
  };

  const fetchCurrentUser = async (token: string) => {
    try {
      const res = await fetch(`${API_BASE_URL}/me`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) {
        setCurrentUser(data.user);
        setIsAuthenticated(true);
      } else {
        console.error(data.error || 'Failed to load user');
      }
    } catch (err) {
      console.error('Failed to load user', err);
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
  };

  const closeAuthModal = () => {
    setShowAuthModal(false);
  };

  const handleLoginSuccess = (token: string, user: AppUser) => {
    setIsAuthenticated(true);
    setCurrentUser(user);
    localStorage.setItem('token', token);
  };

  const handleRegisterSuccess = (token: string, user: AppUser) => {
    setIsAuthenticated(true);
    setCurrentUser(user);
    localStorage.setItem('token', token);
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    setCurrentUser(null);
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
              { key: 'social', label: 'Социальное', icon: '🎉' }
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

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredPosts.map(post => (
            <PostCard key={post.id} post={post} />
          ))}
        </div>

        {filteredPosts.length === 0 && (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">📭</div>
            <h3 className="text-lg font-medium text-gray-600 mb-2">
              Объявлений не найдено
            </h3>
            <p className="text-gray-500">
              Попробуйте изменить фильтры или создайте первое объявление
            </p>
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

      {showCreatePost && (
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