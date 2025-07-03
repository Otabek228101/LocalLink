FROM elixir:1.15-slim

RUN apt-get update && apt-get install -y \
  build-essential \
  nodejs \
  npm \
  git \
  postgresql-client

WORKDIR /app
COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile

CMD ["mix", "phx.server"]
