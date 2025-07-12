defmodule LocallinkApiWeb.MessageController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Chat
  alias LocallinkApi.Chat.Message
  alias LocallinkApi.Guardian

  action_fallback LocallinkApiWeb.FallbackController

  # GET  /api/v1/conversations/:conversation_id/messages
  def index(conn, %{"conversation_id" => cid}) do
    messages = Chat.list_messages(cid)
    render(conn, :index, messages: messages)
  end

  # POST /api/v1/conversations/:conversation_id/messages
  # body: { "body": "..." }
  def create(conn, %{"conversation_id" => cid, "body" => body}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, %Message{} = msg} <- Chat.create_message(cid, user.id, body) do
      conn
      |> put_status(:created)
      |> render(:show, message: msg)
    end
  end
end
