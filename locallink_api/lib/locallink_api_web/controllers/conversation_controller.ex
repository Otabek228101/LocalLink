defmodule LocallinkApiWeb.ConversationController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Chat
  alias Guardian.Plug, as: GPlug

  action_fallback LocallinkApiWeb.FallbackController

  def index(conn, _params) do
    current_user = GPlug.current_resource(conn)
    convs = Chat.list_user_conversations(current_user.id)

    conn
    |> put_status(:ok)
    |> json(%{conversations: Enum.map(convs, &conv_json/1)})
  end

  def create(conn, %{"post_id" => post_id}) when is_binary(post_id) and byte_size(post_id) > 0 do
    current_user = GPlug.current_resource(conn)

    # Валидация UUID формата
    case Ecto.UUID.cast(post_id) do
      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: "Invalid post_id format",
          details: "post_id must be a valid UUID",
          received: post_id
        })

      {:ok, uuid} ->
        case Chat.get_or_create_conversation(uuid, current_user.id) do
          {:ok, conv} ->
            # Загружаем связанные данные
            conv_with_preloads = LocallinkApi.Repo.preload(conv, [:user1, :user2, :post])

            conn
            |> put_status(:created)
            |> json(%{
              message: "Conversation created or found",
              conversation: conv_json(conv_with_preloads)
            })

          {:error, :not_found} ->
            conn
            |> put_status(:not_found)
            |> json(%{
              error: "Post not found",
              post_id: post_id
            })

          {:error, :cannot_chat_with_yourself} ->
            conn
            |> put_status(:bad_request)
            |> json(%{
              error: "Cannot create conversation with yourself",
              details: "You cannot chat with yourself about your own post"
            })

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              error: "Failed to create conversation",
              errors: translate_errors(changeset)
            })

          {:error, reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{
              error: "Unexpected error",
              details: inspect(reason)
            })
        end
    end
  end

  def create(conn, params) do
    post_id = Map.get(params, "post_id")

    cond do
      is_nil(post_id) ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: "Missing required field: post_id",
          received_params: Map.keys(params)
        })

      post_id == "" ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: "post_id cannot be empty"
        })

      true ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: "Invalid post_id",
          received: post_id,
          expected: "Valid UUID string"
        })
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = GPlug.current_resource(conn)

    case Chat.get_conversation(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Conversation not found"})

      conv ->
        if Chat.participant?(conv, current_user.id) do
          conn
          |> put_status(:ok)
          |> json(%{conversation: conv_json(conv)})
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Access denied - you are not a participant"})
        end
    end
  end

  defp conv_json(conv) do
    %{
      id: conv.id,
      post_id: conv.post_id,
      user1_id: conv.user1_id,
      user2_id: conv.user2_id,
      started_by_id: conv.started_by_id,
      inserted_at: conv.inserted_at,
      updated_at: conv.updated_at,
      post: if(conv.post, do: %{
        id: conv.post.id,
        title: conv.post.title,
        category: conv.post.category
      }, else: nil),
      users: [
        if(conv.user1, do: %{
          id: conv.user1.id,
          first_name: conv.user1.first_name,
          last_name: conv.user1.last_name
        }, else: nil),
        if(conv.user2, do: %{
          id: conv.user2.id,
          first_name: conv.user2.first_name,
          last_name: conv.user2.last_name
        }, else: nil)
      ] |> Enum.filter(& &1)
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
