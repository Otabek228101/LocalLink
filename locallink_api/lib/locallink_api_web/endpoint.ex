defmodule LocallinkApiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :locallink_api

  @session_options [
    store: :cookie,
    key: "_locallink_api_key",
    signing_salt: "Adz9OJEO",
    same_site: "Lax"
  ]

  plug Plug.Static,
    at: "/",
    from: :locallink_api,
    gzip: false,
    only: LocallinkApiWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :locallink_api
  end

  plug Plug.RequestId
  plug CORSPlug

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug LocallinkApiWeb.Router
end
