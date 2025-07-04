defmodule LocallinkApi.Offers.Offer do
  @moduledoc """
  Предложение работника выполнить задачу за определенную цену.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "offers" do
    # Цены
    field :original_price, :decimal
    field :offered_price, :decimal
    field :currency, :string, default: "UZS"

    # Контент
    field :message, :string

    # Статус
    field :status, :string, default: "pending"

    # Временные рамки
    field :expires_at, :naive_datetime
    field :estimated_completion, :naive_datetime
    field :accepted_at, :naive_datetime
    field :completed_at, :naive_datetime
    field :work_started_at, :naive_datetime

    # Связи
    belongs_to :post, LocallinkApi.Post
    belongs_to :offerer, LocallinkApi.User         # Кто предлагает услугу
    belongs_to :receiver, LocallinkApi.User        # Кому предлагают (автор поста)
    belongs_to :conversation, LocallinkApi.Chat.Conversation

    timestamps()
  end

  @valid_statuses ["pending", "accepted", "declined", "completed", "cancelled"]

  def changeset(offer, attrs) do
    offer
    |> cast(attrs, [
      :original_price, :offered_price, :currency, :message, :status,
      :expires_at, :estimated_completion, :post_id, :offerer_id, :receiver_id
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

  # Нельзя сделать предложение самому себе
  defp validate_not_self_offer(changeset) do
    offerer_id = get_change(changeset, :offerer_id)
    receiver_id = get_change(changeset, :receiver_id)

    if offerer_id == receiver_id do
      add_error(changeset, :receiver_id, "cannot make offer to yourself")
    else
      changeset
    end
  end

  # Проверка логики цен
  defp validate_price_logic(changeset) do
    original_price = get_change(changeset, :original_price)
    offered_price = get_change(changeset, :offered_price)

    cond do
      # Если есть и original и offered - это counter-offer
      original_price && offered_price && offered_price > original_price ->
        add_error(changeset, :offered_price, "cannot be higher than original price")

      # Должна быть хотя бы одна цена
      is_nil(original_price) && is_nil(offered_price) ->
        add_error(changeset, :offered_price, "either original_price or offered_price must be set")

      true -> changeset
    end
  end
end
