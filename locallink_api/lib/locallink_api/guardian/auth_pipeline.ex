defmodule LocallinkApi.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :locallink_api,
    error_handler: LocallinkApi.Guardian.AuthErrorHandler,
    module: LocallinkApi.Guardian

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
