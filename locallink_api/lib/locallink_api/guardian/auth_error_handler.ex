# ошибки про токе эррор

defmodule LocallinkApi.Guardian.AuthErrorHandler do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2, put_status: 2]

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, _opts) do
    require Logger
    Logger.warn("Auth error: #{inspect(type)}, reason: #{inspect(reason)}")

    message = case type do
      :invalid_token -> "Недействительный токен авторизации"
      :token_expired -> "Токен авторизации истек"
      :no_resource_found -> "Пользователь не найден"
      :already_authenticated -> "Пользователь уже авторизован"
      :not_authenticated -> "Требуется авторизация"
      :invalid_claims -> "Недействительные данные токена"
      :token_not_found -> "Токен авторизации не найден"
      _ -> "Ошибка авторизации: #{to_string(type)}"
    end

    # Определяем HTTP статус
    status_code = case type do
      :not_authenticated -> 401
      :invalid_token -> 401
      :token_expired -> 401
      :token_not_found -> 401
      :no_resource_found -> 401
      :invalid_claims -> 401
      :already_authenticated -> 409
      _ -> 401
    end

    conn
    |> put_status(status_code)
    |> put_resp_content_type("application/json")
    |> json(%{
      error: message,
      type: to_string(type),
      status: status_code
    })
    |> halt()
  end
end
