defmodule LocallinkApi.Chat.Conversation do
  @moduledoc """
  Беседа в чате между двумя пользователями по поводу конкретного поста.
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

  @required_fields ~w(post_id user1_id user2_id started_by_id)a

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:unique_conversation,
         name: :conversations_post_user1_user2_index,
         message: "Conversation already exists")
  end
end
