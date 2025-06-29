# config/runtime.exs
import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

if System.get_env("PHX_SERVER") do
  config :locallink_api, LocallinkApiWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :locallink_api, LocallinkApi.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a real secret in production.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "api.locallink.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :locallink_api, LocallinkApiWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Configure Guardian secret
  guardian_secret =
    System.get_env("GUARDIAN_SECRET_KEY") ||
      raise """
      environment variable GUARDIAN_SECRET_KEY is missing.
      You can generate one by calling: mix guardian.gen.secret
      """

  config :locallink_api, LocallinkApi.Guardian,
    secret_key: guardian_secret

  # Configure Redis
  redis_url = System.get_env("REDIS_URL") || "redis://localhost:6379/0"

  config :redix,
    url: redis_url

  # Configure mailer
  if sendgrid_api_key = System.get_env("SENDGRID_API_KEY") do
    config :locallink_api, LocallinkApi.Mailer,
      adapter: Swoosh.Adapters.Sendgrid,
      api_key: sendgrid_api_key
  end
end
