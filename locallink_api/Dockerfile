# 1. Официальный Elixir-образ + Node.js
FROM elixir:1.14-slim

# 2. Установка зависимостей ОС
RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  curl \
  npm \
  inotify-tools \
  postgresql-client \
  && apt-get clean

# 3. Установка Node.js (для frontend сборки)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# 4. Создание рабочей директории
WORKDIR /app

# 5. Кэшинг зависимостей
COPY mix.exs mix.lock ./
COPY config config
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

# 6. Копирование проекта
COPY . .

# 7. Компиляция
RUN mix deps.compile && mix compile

# 9. Экспонируем порт Phoenix
EXPOSE 4000

# 10. Команда по умолчанию
CMD ["mix", "phx.server"]
