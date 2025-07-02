defmodule LocallinkApi.Guardian.AuthRequiredPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :locallink_api,
    module: LocallinkApi.Guardian,
    error_handler: LocallinkApi.Guardian.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
