defmodule LocallinkApi.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline, otp_app: :locallink_api

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource
end
