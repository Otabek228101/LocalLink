defmodule LocallinkApiWeb.ChatChannel do
  use Phoenix.Channel
  alias LocallinkApi.Chat

  def join("chat:" <> conv_id, _params, socket) do
    {:ok, assign(socket, :conversation_id, conv_id)}
  end

  def handle_in("new_message", %{"body" => body}, socket) do
    user = socket.assigns.current_user
    conv_id = socket.assigns.conversation_id

    case Chat.create_message(conv_id, user.id, body) do
      {:ok, msg} ->
        broadcast!(socket, "new_message", %{message: msg})
        {:noreply, socket}

      {:error, _cs} ->
        push(socket, "error", %{error: "Cannot send message"})
        {:noreply, socket}
    end
  end
end
