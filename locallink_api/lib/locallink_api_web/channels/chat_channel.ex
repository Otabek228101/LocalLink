# логика обмена сообщениями в реальном времени

defmodule LocallinkApiWeb.ChatChannel do
  use Phoenix.Channel

  alias LocallinkApi.Chat

  def join("chat:" <> conversation_id, _params, socket) do
    {:ok, assign(socket, :conversation_id, String.to_integer(conversation_id))}
  end

  def handle_in("new_message", %{"body" => body}, socket) do
    sender = socket.assigns.current_user
    conversation_id = socket.assigns.conversation_id

    case Chat.create_message(conversation_id, sender.id, body) do
      {:ok, message} ->
        broadcast!(socket, "new_message", %{
          id: message.id,
          body: message.body,
          sender_id: sender.id,
          inserted_at: message.inserted_at
        })

        {:noreply, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{error: "Failed to send message"}}, socket}
    end
  end
end
