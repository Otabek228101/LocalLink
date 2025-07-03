defmodule LocallinkApi.Chat.Conversation do
  @moduledoc """
  Represents a chat conversation between two users about a specific post.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    belongs_to :post, LocallinkApi.Post
    belongs_to :user1, LocallinkApi.User
    belongs_to :user2, LocallinkApi.User
    belongs_to :started_by, LocallinkApi.User

    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:post_id, :user1_id, :user2_id, :started_by_id])
    |> validate_required([:post_id, :user1_id, :user2_id, :started_by_id])
    |> unique_constraint(:unique_conversation, name: :conversations_post_user1_user2_index)
  end
end


defmodule LocallinkApi.Chat.Message do
  @moduledoc """
  Represents a message sent between users inside a conversation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :text, :string
    field :read, :boolean, default: false

    belongs_to :conversation, LocallinkApi.Chat.Conversation
    belongs_to :sender, LocallinkApi.User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text, :read, :conversation_id, :sender_id])
    |> validate_required([:text, :conversation_id, :sender_id])
    |> validate_length(:text, min: 1, max: 2000)
  end
end
