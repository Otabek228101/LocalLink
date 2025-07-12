defmodule LocallinkApi.Offers do
  @moduledoc "Контекст для управления предложениями."

  import Ecto.Query, warn: false
  alias LocallinkApi.{Repo, Posts}
  alias LocallinkApi.Offers.Offer
  alias LocallinkApi.Chat

  @doc "Принять оригинальную цену поста"
  def accept_original_price(post_id, offerer_id, attrs \\ %{}) do
    with {:ok, post} <- Posts.get_post(post_id) do
      params = %{
        "post_id"        => post.id,
        "offerer_id"     => offerer_id,
        "receiver_id"    => post.user_id,
        "original_price" => post.price,
        "currency"       => post.currency,
        "status"         => "accepted",
        "message"        => attrs["message"]
      }

      create_offer_with_chat(params)
    end
  end

  @doc "Сделать встречный оффер"
  def make_counter_offer(post_id, offerer_id, offered_price, attrs \\ %{}) do
    with {:ok, post} <- Posts.get_post(post_id) do
      params =
        attrs
        |> Map.put("post_id", post.id)
        |> Map.put("offerer_id", offerer_id)
        |> Map.put("receiver_id", post.user_id)
        |> Map.put("offered_price", offered_price)
        |> Map.put("currency", post.currency)
        |> Map.put("status", "pending")

      create_offer_with_chat(params)
    end
  end

  @doc "Принять оффер"
  def accept_offer(offer_id, user_id) do
    with {:ok, offer} <- get_offer(offer_id),
         true <- offer.receiver_id == user_id and offer.status == "pending"
    do
      offer
      |> Offer.changeset(%{status: "accepted", accepted_at: NaiveDateTime.utc_now()})
      |> Repo.update()
      |> tap(fn
        {:ok, upd} -> decline_other_offers(upd.post_id, upd.id)
        _ -> :ok
      end)
    else
      _ -> {:error, "Cannot accept this offer"}
    end
  end

  @doc "Отклонить оффер"
  def decline_offer(offer_id, user_id) do
    with {:ok, offer} <- get_offer(offer_id),
         true <- offer.receiver_id == user_id and offer.status == "pending"
    do
      offer
      |> Offer.changeset(%{status: "declined"})
      |> Repo.update()
    else
      _ -> {:error, "Cannot decline this offer"}
    end
  end

  @doc "Завершить оффер"
  def complete_offer(offer_id, user_id) do
    with {:ok, offer} <- get_offer(offer_id),
         true <- offer.status == "accepted" and (offer.offerer_id == user_id or offer.receiver_id == user_id)
    do
      offer
      |> Offer.changeset(%{status: "completed", completed_at: NaiveDateTime.utc_now()})
      |> Repo.update()
    else
      _ -> {:error, "Cannot complete this offer"}
    end
  end

  @doc "Список офферов для поста"
  def list_offers_for_post(post_id) do
    Offer
    |> where(post_id: ^post_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc "Список офферов пользователя"
  def list_user_offers(user_id) do
    Offer
    |> where([o], o.offerer_id == ^user_id or o.receiver_id == ^user_id)
    |> Repo.all()
  end

  # === Внутренние ===

  # Создаёт оффер и запускает чат — внутри транзакции.
  # Возвращает {:ok, offer} или {:error, changeset|:self_offer}.
  defp create_offer_with_chat(params) do
    # защита от само-офера
    if params["offerer_id"] == params["receiver_id"] do
      {:error, "Cannot make offer to yourself"}
    else
      Repo.transaction(fn ->
        case %Offer{} |> Offer.changeset(params) |> Repo.insert() do
          {:ok, offer} ->
            Chat.start_conversation(offer.post_id, offer.offerer_id, offer.receiver_id)
            offer

          {:error, cs} ->
            Repo.rollback(cs)
        end
      end)
      |> case do
        {:ok, offer} -> {:ok, offer}
        {:error, cs} -> {:error, cs}
      end
    end
  end

  # Получить оффер по id
  defp get_offer(id) do
    case Repo.get(Offer, id) do
      nil   -> {:error, :not_found}
      offer -> {:ok, offer}
    end
  end

  # Отклонить все остальные офферы для данного поста
  defp decline_other_offers(post_id, accepted_offer_id) do
    Offer
    |> where([o],
         o.post_id == ^post_id and
         o.id != ^accepted_offer_id and
         o.status == "pending"
       )
    |> Repo.update_all(set: [status: "declined"])
  end
end
