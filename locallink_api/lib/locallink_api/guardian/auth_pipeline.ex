defmodule LocallinkApi.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :locallink_api,
    module: LocallinkApi.Guardian,
    error_handler: LocallinkApiWeb.AuthErrorHandler

  # извлекаем токен из заголовка Authorization: Bearer ...
  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  # убеждаемся, что токен валидный
  plug Guardian.Plug.EnsureAuthenticated
  # сразу грузим ресурс (пользователя) в conn
  plug Guardian.Plug.LoadResource
end
