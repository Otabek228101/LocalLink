defmodule LocallinkApi.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  # ИСПРАВЛЕНО: правильные алиасы
  alias LocallinkApi.Chat.Conversation
  alias LocallinkApi.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :body, :string
    field :read, :boolean, default: false

    belongs_to :conversation, Conversation, type: :binary_id
    belongs_to :sender, User, type: :binary_id

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :sender_id, :body, :read])
    |> validate_required([:conversation_id, :sender_id, :body])
    |> validate_length(:body, min: 1, max: 1000)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:sender_id)
  end
end
