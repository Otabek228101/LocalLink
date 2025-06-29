# config/prod.exs
import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
config :locallink_api, LocallinkApiWeb.Endpoint,
  url: [host: "api.locallink.com", port: 443, scheme: "https"],
  http: [
    ip: {0, 0, 0, 0, 0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4000")
  ],
  secret_key_base: {:system, "SECRET_KEY_BASE"},
  check_origin: [
    "https://locallink.com",
    "https://www.locallink.com",
    "https://app.locallink.com"
  ]

# Configure SSL
config :locallink_api, LocallinkApiWeb.Endpoint,
  https: [
    port: 443,
    cipher_suite: :strong,
    keyfile: {:system, "SSL_KEY_PATH"},
    certfile: {:system, "SSL_CERT_PATH"}
  ]

# Configures the database
config :locallink_api, LocallinkApi.Repo,
  url: {:system, "DATABASE_URL"},
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  socket_options: [:inet6],
  # Enable PostGIS in production
  types: LocallinkApi.PostgresTypes

# Configure Guardian for production
config :locallink_api, LocallinkApi.Guardian,
  issuer: "locallink_api",
  secret_key: {:system, "GUARDIAN_SECRET_KEY"}

# Configure Redis for production
config :redix,
  url: {:system, "REDIS_URL"}

# Configure mailer for production
config :locallink_api, LocallinkApi.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: {:system, "SENDGRID_API_KEY"}

# Do not print debug messages in production
config :logger, level: :info

# Configure CORS for production
config :cors_plug,
  origin: [
    "https://locallink.com",
    "https://www.locallink.com",
    "https://app.locallink.com"
  ],
  max_age: 86400,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]

# Runtime production config is handled in runtime.exs
