defmodule LocallinkApi.Chat.Message do
  @moduledoc """
  Сообщение внутри беседы.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :body, :string
    field :read, :boolean, default: false

    belongs_to :conversation, LocallinkApi.Chat.Conversation
    belongs_to :sender, LocallinkApi.User

    timestamps()
  end

  @required_fields ~w(body conversation_id sender_id)a

  def changeset(message, attrs) do
    message
    |> cast(attrs, @required_fields ++ [:read])
    |> validate_required(@required_fields)
    |> validate_length(:body, min: 1, max: 2_000)
  end
end
