defmodule LocallinkApi.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  # ИСПРАВЛЕНО: правильный алиас
  alias LocallinkApi.User
  alias LocallinkApi.Post

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    field :started_by_id, :binary_id

    belongs_to :post, Post, type: :binary_id
    belongs_to :user1, User, type: :binary_id
    belongs_to :user2, User, type: :binary_id

    has_many :messages, LocallinkApi.Chat.Message, foreign_key: :conversation_id

    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:post_id, :user1_id, :user2_id, :started_by_id])
    |> validate_required([:post_id, :user1_id, :user2_id, :started_by_id])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:user1_id)
    |> foreign_key_constraint(:user2_id)
    |> validate_different_users()
  end

  # Проверка что user1_id != user2_id
  defp validate_different_users(changeset) do
    user1_id = get_change(changeset, :user1_id) || get_field(changeset, :user1_id)
    user2_id = get_change(changeset, :user2_id) || get_field(changeset, :user2_id)

    if user1_id && user2_id && user1_id == user2_id do
      add_error(changeset, :user2_id, "cannot be the same as user1_id")
    else
      changeset
    end
  end
end
