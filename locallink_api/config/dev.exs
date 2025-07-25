#Специальные настройки для разработчиков

import Config

# подключение к db
config :locallink_api, LocallinkApi.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "db",
  database: "locallink_api_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  types: LocallinkApi.PostgresTypes

# Для целей разработки мы отключаем любой кэш и включаем отладку и перезагрузку кода.
# запуск сервера
config :locallink_api, LocallinkApiWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "your-very-long-secret-key-base-for-development-make-it-64-characters",
  watchers: []

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Configure Guardian for development
config :locallink_api, LocallinkApi.Guardian,
  issuer: "locallink_api",
  secret_key: "xQmA78HdQp3hKxLs+VhqWz1d9UebCxlZc6Agyb8fWTzt1YKqvSBRYk+Ak0CB+I8N"

# Disable Swoosh API client as it is only required for production adapters
config :swoosh, :api_client, false

# Configure mailer for development
config :locallink_api, LocallinkApi.Mailer,
  adapter: Swoosh.Adapters.Local

# Configure Redis for development
config :redix,
  url: "redis://localhost:6379/0"

# Enable dev routes for dashboard and mailbox
config :locallink_api, dev_routes: true
