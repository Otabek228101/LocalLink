# Use Elixir official image with Erlang/OTP 26 and Elixir 1.15
FROM elixir:1.15-otp-26 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    npm \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set build ENV
ENV MIX_ENV=prod

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create app directory
WORKDIR /app

# Copy mix files
COPY mix.exs ./

# Create empty mix.lock if it doesn't exist
RUN touch mix.lock

# Install mix dependencies
RUN mix deps.get --only prod

# Copy config files
COPY config config

# Copy lib, priv and other app files
COPY lib lib
COPY priv priv

# Compile the project
RUN mix compile

# Build the release
RUN mix release

# ---- Application Stage ----
FROM debian:bullseye-slim AS app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    openssl \
    ca-certificates \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# Create a user to run the app
RUN useradd --create-home app
WORKDIR /home/app
USER app

# Copy the release from builder stage
COPY --from=builder --chown=app:app /app/_build/prod/rel/locallink_api ./

# Expose port
EXPOSE 4000

# Set environment
ENV HOME=/home/app

# Start the Phoenix app
CMD ["./bin/locallink_api", "start"]