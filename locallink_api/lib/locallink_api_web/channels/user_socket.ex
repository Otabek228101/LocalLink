defmodule LocallinkApiWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "chat:*", LocallinkApiWeb.ChatChannel
  channel "notifications:*", LocallinkApiWeb.NotificationChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case LocallinkApi.Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        case LocallinkApi.Guardian.resource_from_claims(claims) do
          {:ok, user} -> {:ok, assign(socket, :current_user, user)}
          _ -> :error
        end
      _ -> :error
    end
  end

  def id(_socket), do: nil
end
