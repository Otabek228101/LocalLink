defmodule LocallinkApi.Offers.Offer do
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  use Ecto.Schema
  import Ecto.Changeset

  schema "offers" do
    field :original_price, :decimal
    field :offered_price, :decimal
    field :currency, :string, default: "UZS"
    field :message, :string
    field :status, :string, default: "pending"

    field :expires_at, :naive_datetime
    field :estimated_completion, :naive_datetime
    field :accepted_at, :naive_datetime
    field :completed_at, :naive_datetime
    field :work_started_at, :naive_datetime

    belongs_to :post, LocallinkApi.Post
    belongs_to :offerer, LocallinkApi.User
    belongs_to :receiver, LocallinkApi.User
    belongs_to :conversation, LocallinkApi.Chat.Conversation

    timestamps()
  end

  @valid_statuses ["pending", "accepted", "declined", "completed", "cancelled"]

  def changeset(offer, attrs) do
    offer
    |> cast(attrs, [
      :post_id, :offerer_id, :receiver_id,
      :original_price, :offered_price, :currency,
      :message, :status,
      :expires_at, :estimated_completion,
      :accepted_at, :completed_at, :work_started_at,
      :conversation_id
    ])
    |> validate_required([:post_id, :offerer_id, :receiver_id])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:original_price, greater_than: 0)
    |> validate_number(:offered_price, greater_than: 0)
    |> validate_length(:message, max: 500)
    |> validate_not_self_offer()
    |> validate_price_logic()
    |> unique_constraint([:post_id, :offerer_id],
         message: "You already made an offer for this post")
  end

  defp validate_not_self_offer(changeset) do
    if get_field(changeset, :offerer_id) == get_field(changeset, :receiver_id) do
      add_error(changeset, :receiver_id, "cannot make offer to yourself")
    else
      changeset
    end
  end

  defp validate_price_logic(changeset) do
    op = get_field(changeset, :original_price)
    ep = get_field(changeset, :offered_price)

    cond do
      op && ep && ep > op ->
        add_error(changeset, :offered_price, "cannot be higher than original price")
      is_nil(op) && is_nil(ep) ->
        add_error(changeset, :offered_price, "either original_price or offered_price must be set")
      true ->
        changeset
    end
  end
end
