# Используем образ с предустановленными hex и rebar
FROM hexpm/elixir:1.15.7-erlang-26.1.2-debian-bullseye-20231009-slim

# Устанавливаем системные зависимости
RUN apt-get update && apt-get install -y \
  build-essential \
  nodejs \
  npm \
  git \
  postgresql-client \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Копируем файлы зависимостей
COPY mix.exs mix.lock ./

# Устанавливаем зависимости
RUN mix deps.get

# Копируем остальное приложение
COPY . .

# Компилируем
RUN mix compile

EXPOSE 4000

CMD ["mix", "phx.server"]
