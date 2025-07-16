defmodule LocallinkApiWeb.UserSocket do
  use Phoenix.Socket
  alias LocallinkApi.Guardian

  channel "chat:*", LocallinkApiWeb.ChatChannel

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(%{"token" => token}, socket, _connect_info) do
    case Guardian.resource_from_token(token) do
      {:ok, user, _claims} ->
        {:ok, assign(socket, :current_user, user)}
      _ ->
        :error
    end
  end

  def id(_socket), do: nil
end
