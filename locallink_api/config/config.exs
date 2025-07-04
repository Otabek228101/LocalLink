# Центральная конфигурация всего приложения
import Config

# настройки проекта
config :locallink_api,
  ecto_repos: [LocallinkApi.Repo]

# подкл к db postgres
config :locallink_api, LocallinkApi.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "locallink_api_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  types: LocallinkApi.PostgresTypes

# настройки сервера
config :locallink_api, LocallinkApiWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: LocallinkApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LocallinkApi.PubSub,
  live_view: [signing_salt: "your-signing-salt"]

# Configures the mailer
config :locallink_api, LocallinkApi.Mailer, adapter: Swoosh.Adapters.Local

# JWT (JSON Web Token) авторизация чере Guardian (для безопастности)
config :locallink_api, LocallinkApi.Guardian,
  issuer: "locallink_api",
  secret_key: "xQmA78HdQp3hKxLs+VhqWz1d9UebCxlZc6Agyb8fWTzt1YKqvSBRYk+Ak0CB+I8N"

# logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# CORS (чтобы фронтенд мог обращаться к бэкенду)
config :cors_plug,
  origin: ["http://localhost:3000", "http://localhost:3001"],
  max_age: 86400,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  headers: ["Authorization", "Content-Type"]

# Redis для кэширования и сессий
config :redix,
  url: "redis://localhost:6379/0"

# Импортируйте конфигурацию, специфичную для среды. Это должно остаться внизу
# этого файла, чтобы он переопределял конфигурацию, определенную выше.
import_config "#{config_env()}.exs"
