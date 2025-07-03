defmodule LocallinkApi.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :body, :string
    belongs_to :conversation, LocallinkApi.Chat.Conversation
    belongs_to :sender, LocallinkApi.Accounts.User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body, :conversation_id, :sender_id])
    |> validate_required([:body, :conversation_id, :sender_id])
  end
end
