defmodule LocallinkApiWeb.MessageController do
  use LocallinkApiWeb, :controller
  alias LocallinkApi.Chat
  alias LocallinkApi.Chat.{Conversation, Message}
  alias Guardian.Plug, as: GPlug
  action_fallback LocallinkApiWeb.FallbackController

  # GET  /conversations/:id/messages
  def index(conn, %{"id" => conv_id}) do
    current_user = GPlug.current_resource(conn)
    with %Conversation{} = conv <- Chat.get_conversation(conv_id),
         true <- Chat.participant?(conv, current_user.id) do
      msgs = Chat.list_messages(conv_id)
      conn
      |> put_status(:ok)
      |> json(%{messages: Enum.map(msgs, &msg_json/1)})
    else
      nil   -> conn |> put_status(:not_found)  |> json(%{error: "Conversation not found"})
      false -> conn |> put_status(:forbidden) |> json(%{error: "Not a participant"})
    end
  end

  # POST /conversations/:id/messages
  def create(conn, %{"id" => conv_id, "body" => body})
      when is_binary(body) and byte_size(body) > 0 do
    current_user = GPlug.current_resource(conn)

    with %Conversation{} = conv <- Chat.get_conversation(conv_id),
         true <- Chat.participant?(conv, current_user.id),
         {:ok, %Message{} = msg} <- Chat.create_message(conv_id, current_user.id, body) do

      # Preload sender для ответа
      msg = LocallinkApi.Repo.preload(msg, :sender)

      conn
      |> put_status(:created)
      |> json(%{message: msg_json(msg)})
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Conversation not found"})

      false ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Not a participant"})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "Validation failed",
          errors: translate_errors(cs)
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to create message: #{inspect(reason)}"})
    end
  end

  def create(conn, params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Invalid request",
      details: "Required: conversation_id and body",
      received: params
    })
  end

  # Исправленная функция msg_json
  defp msg_json(msg) do
    %{
      id: msg.id,
      conversation_id: msg.conversation_id,
      sender_id: msg.sender_id,
      body: msg.body,
      read: msg.read,
      inserted_at: msg.inserted_at,
      updated_at: msg.updated_at,
      sender: if(msg.sender, do: %{
        id: msg.sender.id,
        first_name: msg.sender.first_name,
        last_name: msg.sender.last_name
      }, else: nil)
    }
  end

  # Добавляем функцию для обработки ошибок changeset
  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
