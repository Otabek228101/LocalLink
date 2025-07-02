defmodule LocallinkApiWeb.FallbackController do
  @moduledoc """
  Обработчик ошибок для API контроллеров.
  Гарантирует, что все ошибки возвращаются в формате JSON.
  """

  use LocallinkApiWeb, :controller

  # Обработка ошибок валидации changeset
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      error: "Validation failed",
      errors: translate_errors(changeset)
    })
  end

  # Обработка ошибки "не найдено"
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{
      error: "Resource not found",
      status: 404
    })
  end

  # Обработка ошибки "нет авторизации"
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{
      error: "Unauthorized access",
      status: 401
    })
  end

  # Обработка ошибки "доступ запрещен"
  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> json(%{
      error: "Access forbidden",
      status: 403
    })
  end

  # Обработка любых других ошибок
  def call(conn, {:error, reason}) when is_binary(reason) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: reason,
      status: 400
    })
  end

  # Fallback для неизвестных ошибок
  def call(conn, _error) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{
      error: "Internal server error",
      status: 500
    })
  end

  # Обработка несуществующих маршрутов
  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> json(%{
      error: "API endpoint not found",
      status: 404,
      path: conn.request_path
    })
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
