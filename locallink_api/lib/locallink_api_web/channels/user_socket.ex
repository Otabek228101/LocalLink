defmodule LocallinkApiWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "chat:*", LocallinkApiWeb.ChatChannel
  channel "notifications:*", LocallinkApiWeb.NotificationChannel

  #Параметры сокета передаются от клиента и могут использоваться для проверки подлинности пользователя.
  def connect(%{"token" => token}, socket, _connect_info) do
    case LocallinkApi.Guardian.resource_from_token(token) do
      {:ok, user, _claims} ->
        {:ok, assign(socket, :current_user, user)}

      _ ->
        :error
    end
  end

  def id(_socket), do: nil
end
