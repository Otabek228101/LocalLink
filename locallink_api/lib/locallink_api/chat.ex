defmodule LocallinkApi.Chat do
  @moduledoc "Контекст для работы с беседами и сообщениями"

  import Ecto.Query, warn: false
  alias LocallinkApi.{Repo, Posts}
  alias LocallinkApi.Chat.{Conversation, Message}

  @doc "Получить или создать беседу по post_id и current_user_id."
  def get_or_create_conversation(post_id, current_user_id) do
    with {:ok, post} <- Posts.get_post(post_id) do
      participant_id = post.user_id

      # Проверяем не пытается ли пользователь создать беседу с самим собой
      if participant_id == current_user_id do
        {:error, :cannot_chat_with_yourself}
      else
        query =
          from(c in Conversation,
            where:
              c.post_id == ^post_id and
                ((c.user1_id == ^participant_id and c.user2_id == ^current_user_id) or
                   (c.user1_id == ^current_user_id and c.user2_id == ^participant_id))
          )

        case Repo.one(query) do
          nil ->
            # Создаём новую беседу
            %Conversation{}
            |> Conversation.changeset(%{
              post_id: post_id,
              user1_id: participant_id,
              user2_id: current_user_id,
              started_by_id: current_user_id
            })
            |> Repo.insert()

          conversation ->
            # Возвращаем существующую беседу
            {:ok, conversation}
        end
      end
    else
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @doc "Создаёт новую беседу"
  def start_conversation(post_id, user1_id, user2_id) do
    if user1_id == user2_id do
      {:error, :cannot_chat_with_yourself}
    else
      %Conversation{}
      |> Conversation.changeset(%{
        post_id: post_id,
        user1_id: user1_id,
        user2_id: user2_id,
        started_by_id: user1_id
      })
      |> Repo.insert()
    end
  end

  @doc "Получить беседу по id."
  def get_conversation(id) do
    case Repo.get(Conversation, id) do
      nil -> nil
      conv -> Repo.preload(conv, [:user1, :user2, :post])
    end
  end

  @doc "Список бесед пользователя"
  def list_user_conversations(user_id) do
    Conversation
    |> where([c], c.user1_id == ^user_id or c.user2_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> preload([:user1, :user2, :post])
    |> Repo.all()
  end

  @doc "Проверяет, что пользователь — участник беседы"
  def participant?(%Conversation{user1_id: u1, user2_id: u2}, user_id) do
    user_id == u1 or user_id == u2
  end

  @doc "Список сообщений беседы"
  def list_messages(conversation_id) do
    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> order_by(asc: :inserted_at)
    |> preload(:sender)
    |> Repo.all()
  end

  @doc "Создаёт сообщение с улучшенной обработкой ошибок"
  def create_message(conversation_id, sender_id, body) do
    # Проверяем существование беседы
    case get_conversation(conversation_id) do
      nil ->
        {:error, :conversation_not_found}

      conv ->
        # Проверяем права доступа
        if participant?(conv, sender_id) do
          %Message{}
          |> Message.changeset(%{
            conversation_id: conversation_id,
            sender_id: sender_id,
            body: String.trim(body)
          })
          |> Repo.insert()
        else
          {:error, :not_participant}
        end
    end
  end
end
