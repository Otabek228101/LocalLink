#Управляет диалогами и сообщениями

defmodule LocallinkApi.Chat do
  @moduledoc """
  Контекст чата: обрабатывает разговоры и сообщения пользователей.
  """

  import Ecto.Query, warn: false
  alias LocallinkApi.Repo

  alias LocallinkApi.Chat.{Conversation, Message}
  alias LocallinkApi.Post
  alias LocallinkApi.User

  @doc """
  Запускает новый диалог между двумя пользователями о конкретной публикации, если она еще не существует.
  """
  def start_conversation(post_id, user_id, current_user_id) do
    post = Repo.get!(Post, post_id)

    query = from c in Conversation,
      where: c.post_id == ^post_id and ((c.user1_id == ^user_id and c.user2_id == ^current_user_id) or (c.user1_id == ^current_user_id and c.user2_id == ^user_id))

    case Repo.one(query) do
      nil ->
        %Conversation{}
        |> Conversation.changeset(%{
          post_id: post_id,
          user1_id: post.user_id,
          user2_id: current_user_id,
          started_by_id: current_user_id
        })
        |> Repo.insert()

      conversation ->
        {:ok, conversation}
    end
  end

  @doc """
  Отправляет сообщение внутри беседы.
  """
  def send_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Возвращает все сообщения в переписке, включая последние.
  """
  def list_messages(conversation_id) do
    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> order_by(asc: :inserted_at)
    |> preload(:sender)
    |> Repo.all()
  end

  @doc """
  Содержит список всех разговоров пользователя.
  """
  def list_user_conversations(user_id) do
    Conversation
    |> where([c], c.user1_id == ^user_id or c.user2_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> preload([:user1, :user2, :post])
    |> Repo.all()
  end


  def list_user_conversations(user_id) do
    from(c in Conversation,
      where: c.user1_id == ^user_id or c.user2_id == ^user_id,
      preload: [:user1, :user2]
    )
    |> Repo.all()
  end

  def get_or_create_conversation(user_id, participant_id) do
    case Repo.get_by(Conversation, user1_id: user_id, user2_id: participant_id) ||
         Repo.get_by(Conversation, user1_id: participant_id, user2_id: user_id) do
      nil ->
        %Conversation{}
        |> Conversation.changeset(%{user1_id: user_id, user2_id: participant_id})
        |> Repo.insert()

      conversation ->
        {:ok, conversation}
    end
  end

  def get_conversation!(id), do: Repo.get!(Conversation, id) |> Repo.preload([:user1, :user2])

  def list_messages(conversation_id) do
    from(m in Message,
      where: m.conversation_id == ^conversation_id,
      order_by: [asc: m.inserted_at],
      preload: [:sender]
    )
    |> Repo.all()
  end

  def create_message(conversation_id, sender_id, body) do
    %Message{}
    |> Message.changeset(%{
      conversation_id: conversation_id,
      sender_id: sender_id,
      body: body
    })
    |> Repo.insert()
  end
end
