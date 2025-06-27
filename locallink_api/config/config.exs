# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :locallink_api,
  ecto_repos: [LocallinkApi.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :locallink_api, LocallinkApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: LocallinkApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LocallinkApi.PubSub,
  live_view: [signing_salt: "5KM147ar"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :locallink_api, LocallinkApi.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :locallink_api, LocallinkApi.Guardian,
  issuer: "locallink_api",
  secret_key: "uAMx4T5+4cXGXK0D7k0D4pYq3vNl6g7h8j9k0l1m2n3o4p5q6r7s8t9u0v1w2x3y4z5A6B7C8D9E0F1G2H3I4J5K6L7M8N9O0P1Q2R3S4T5U"
