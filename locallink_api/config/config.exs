# config/config.exs
import Config

# Configure your database
config :locallink_api,
  ecto_repos: [LocallinkApi.Repo]

config :locallink_api, LocallinkApi.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "locallink_api_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  # PostGIS extension for geolocation features
  types: LocallinkApi.PostgresTypes

# Configures the endpoint
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

# Configure Guardian for JWT authentication
config :locallink_api, LocallinkApi.Guardian,
  issuer: "locallink_api",
  secret_key: "xQmA78HdQp3hKxLs+VhqWz1d9UebCxlZc6Agyb8fWTzt1YKqvSBRYk+Ak0CB+I8N"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure CORS
config :cors_plug,
  origin: ["http://localhost:3000", "http://localhost:3001"],
  max_age: 86400,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  headers: ["Authorization", "Content-Type"]

# Redis configuration for caching and sessions
config :redix,
  url: "redis://localhost:6379/0"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
