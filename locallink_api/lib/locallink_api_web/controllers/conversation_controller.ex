defmodule LocallinkApiWeb.ConversationController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Chat
  alias LocallinkApi.Chat.Conversation
  alias LocallinkApi.Guardian

  action_fallback LocallinkApiWeb.FallbackController

  # GET /api/v1/conversations
  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    conversations = Chat.list_user_conversations(user.id)
    render(conn, :index, conversations: conversations)
  end

  # GET /api/v1/conversations/:id
  def show(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    with %Conversation{} = convo <- Chat.get_conversation!(id),
         true <- convo.user1_id == user.id or convo.user2_id == user.id do
      render(conn, :show, conversation: convo)
    else
      _ -> conn |> put_status(:forbidden) |> json(%{error: "Not authorized"})
    end
  end

  # POST /api/v1/conversations
  # body: { "post_id": "...", "participant_id": "..." }
  def create(conn, %{"post_id" => post_id, "participant_id" => participant_id}) do
    current_user = Guardian.Plug.current_resource(conn)

    with {:ok, %Conversation{} = convo} <-
           Chat.start_conversation(post_id, participant_id, current_user.id) do
      conn
      |> put_status(:created)
      |> render(:show, conversation: convo)
    end
  end
end
