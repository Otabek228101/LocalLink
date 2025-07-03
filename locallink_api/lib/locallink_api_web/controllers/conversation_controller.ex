defmodule LocallinkApiWeb.ConversationController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Chat
  alias LocallinkApi.Chat.Conversation

  action_fallback LocallinkApiWeb.FallbackController

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    conversations = Chat.list_user_conversations(user.id)
    render(conn, :index, conversations: conversations)
  end

  def create(conn, %{"participant_id" => participant_id}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, %Conversation{} = conversation} <- Chat.get_or_create_conversation(user.id, participant_id) do
      conn
      |> put_status(:created)
      |> render(:show, conversation: conversation)
    end
  end

  def show(conn, %{"id" => id}) do
    conversation = Chat.get_conversation!(id)
    render(conn, :show, conversation: conversation)
  end
end
