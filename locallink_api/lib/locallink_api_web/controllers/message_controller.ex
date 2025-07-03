defmodule LocallinkApiWeb.MessageController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Chat
  alias LocallinkApi.Chat.Message

  action_fallback LocallinkApiWeb.FallbackController

  def index(conn, %{"conversation_id" => conversation_id}) do
    messages = Chat.list_messages(conversation_id)
    render(conn, :index, messages: messages)
  end

  def create(conn, %{"conversation_id" => conversation_id, "body" => body}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, %Message{} = message} <- Chat.create_message(conversation_id, user.id, body) do
      conn
      |> put_status(:created)
      |> render(:show, message: message)
    end
  end
end
