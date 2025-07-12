ZZZ goyda ZOV
# 🚀 LOCALLINK

**Connecting Local Needs, Skills, and Community**

LOCALLINK - это платформа на базе геолокации для связи местных потребностей, навыков и сообщества. Поддерживает работу с объявлениями, событиями, предложениями услуг и уведомлениями в реальном времени.

## 📋 Что изменилось

### ✅ Исправлены проблемы:
- **PostGIS Error** - теперь используется образ `postgis/postgis:13-3.1`
- **База данных** - исправлено имя БД на `locallink_api_dev`
- **Автоматизация** - добавлены скрипты для быстрого запуска
- **Тестовые данные** - готовые данные для тестирования

### 🆕 Новые возможности:
- Автоматическая инициализация PostGIS
- Health checks для всех сервисов
- Volumes для сохранения данных
- Улучшенный Dockerfile с кэшированием
- Скрипт быстрого запуска

## 🚀 Быстрый запуск

### Вариант 1: Автоматический запуск (Рекомендуется)

```bash
# Сделать скрипт исполняемым
chmod +x start.sh

# Запустить проект одной командой
./start.sh
```

### Вариант 2: Пошаговый запуск

```bash
# 1. Остановить существующие контейнеры
docker-compose down

# 2. Собрать и запустить сервисы
docker-compose up --build -d

# 3. Проверить статус
docker-compose ps

# 4. Проверить здоровье API
curl http://localhost:4000/health

# 5. Заполнить тестовыми данными (опционально)
docker-compose exec web mix run priv/repo/seeds.exs
```

## 🔧 Управление проектом

### Основные команды

```bash
# Запуск всех сервисов
docker-compose up -d

# Сборка с пересозданием
docker-compose up --build -d

# Остановка всех сервисов
docker-compose down

# Просмотр логов
docker-compose logs -f web    # API сервер
docker-compose logs -f db     # База данных
docker-compose logs -f redis  # Redis

# Статус сервисов
docker-compose ps
```

### Работа с базой данных

```bash
# Подключение к БД
docker-compose exec db psql -U postgres locallink_api_dev

# Миграции
docker-compose exec web mix ecto.migrate

# Откат миграций
docker-compose exec web mix ecto.rollback

# Сброс БД
docker-compose exec web mix ecto.drop
docker-compose exec web mix ecto.create
docker-compose exec web mix ecto.migrate
```

### Разработка

```bash
# Интерактивная консоль Elixir
docker-compose exec web iex -S mix

# Установка зависимостей
docker-compose exec web mix deps.get

# Компиляция
docker-compose exec web mix compile

# Тесты
docker-compose exec web mix test
```

## 🌐 API Endpoints

### 🔐 Аутентификация
```bash
# Регистрация
curl -X POST http://localhost:4000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123",
      "first_name": "Тест",
      "last_name": "Пользователь"
    }
  }'

# Вход
curl -X POST http://localhost:4000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Профиль (требует токен)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:4000/api/v1/me
```

### 📋 Объявления/Посты
```bash
# Список постов
curl http://localhost:4000/api/v1/posts

# Создание поста
curl -X POST http://localhost:4000/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "post": {
      "title": "Нужен сантехник",
      "description": "Протекает кран",
      "category": "task",
      "post_type": "seeking",
      "location": "Ташкент, Мирзо-Улугбек",
      "price": 100000,
      "urgency": "today"
    }
  }'

# Горячие зоны активности
curl http://localhost:4000/api/v1/hot-zones
```

### 🎉 События
```bash
# Доступные события
curl http://localhost:4000/api/v1/events/available

# Присоединиться к событию
curl -X POST http://localhost:4000/api/v1/posts/EVENT_ID/join \
  -H "Authorization: Bearer YOUR_TOKEN"

# Покинуть событие
curl -X DELETE http://localhost:4000/api/v1/posts/EVENT_ID/leave \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🗄️ Структура базы данных

### Основные таблицы:
- **users** - Пользователи системы
- **posts** - Объявления/события (с PostGIS геолокацией)
- **offers** - Предложения работников
- **reviews** - Отзывы о выполненной работе
- **notifications** - Система уведомлений
- **conversations/messages** - Чат между пользователями

### PostGIS возможности:
- Поиск по радиусу вокруг координат
- Горячие зоны активности
- Геопространственные индексы для быстрого поиска

## 🧪 Тестовые данные

После запуска `./start.sh` или выполнения:
```bash
docker-compose exec web mix run priv/repo/seeds.exs
```

Будут созданы:
- 5 тестовых пользователей
- 10+ объявлений разных категорий
- События в разных районах Ташкента

### Тестовые аккаунты:
```
📧 akmal@locallink.uz     | 🔑 password123
📧 dilnoza@locallink.uz   | 🔑 password123
📧 bobur@locallink.uz     | 🔑 password123
📧 madina@locallink.uz    | 🔑 password123
📧 javohir@locallink.uz   | 🔑 password123
```

## 🏗️ Архитектура

```
┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  React/Next.js  │
│    (Mobile)     │    │   (Web Client)  │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────────────────┼──────────────────────┐
                                 │                      │
                    ┌─────────────┴───────────┐         │
                    │   Phoenix API Server    │         │
                    │     (Elixir/OTP)       │         │
                    └─────────┬───────────────┘         │
                              │                         │
        ┌─────────────────────┼─────────────────────────┼─────────┐
        │                     │                         │         │
┌───────┴────────┐  ┌─────────┴─────────┐  ┌────────────┴─────────┐
│  PostgreSQL    │  │      Redis        │  │     WebSocket        │
│  + PostGIS     │  │   (Кэш/Сессии)   │  │  (Реальное время)    │
│ (Геоданные)    │  │                   │  │                      │
└────────────────┘  └───────────────────┘  └──────────────────────┘
```

## 🐛 Устранение неисправностей

### PostGIS ошибки
```bash
# Если PostGIS не работает
docker-compose down
docker-compose pull db
docker-compose up --build -d
```

### Проблемы с портами
```bash
# Проверить занятые порты
lsof -i :4000
lsof -i :5432

# Остановить все контейнеры
docker-compose down
docker stop $(docker ps -aq)
```

### Проблемы с базой данных
```bash
# Полный сброс БД
docker-compose exec web mix ecto.drop
docker-compose exec web mix ecto.create
docker-compose exec web mix ecto.migrate
docker-compose exec web mix run priv/repo/seeds.exs
```

### Проблемы с зависимостями
```bash
# Пересобрать контейнер
docker-compose build --no-cache web
docker-compose up -d
```

## 📊 Мониторинг

```bash
# Статус сервисов
curl http://localhost:4000/health

# Использование ресурсов
docker stats

# Использование диска
docker system df

# Логи в реальном времени
docker-compose logs -f
```

## 🔧 Конфигурация

### Переменные окружения:
- `DATABASE_URL` - строка подключения к БД
- `REDIS_URL` - строка подключения к Redis
- `MIX_ENV` - окружение (dev/test/prod)

### Файлы конфигурации:
- `config/dev.exs` - разработка
- `config/prod.exs` - production
- `config/test.exs` - тестирование

## 📞 Поддержка

- **Health Check:** http://localhost:4000/health
- **API Docs:** Смотрите endpoints выше
- **Логи:** `docker-compose logs -f web`

---

**LOCALLINK** - Соединяем людей локально! 🤝

Developed for Hackathon 2025 🏆
