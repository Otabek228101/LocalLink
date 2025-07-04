defmodule LocallinkApi.Offers do
  @moduledoc """
  Контекст для управления предложениями работников.
  """

  import Ecto.Query, warn: false
  alias LocallinkApi.Repo
  alias LocallinkApi.Offers.Offer
  alias LocallinkApi.Chat
  alias LocallinkApi.Posts

  @doc """
  Создать предложение принять оригинальную цену.
  """
  def accept_original_price(post_id, offerer_id, attrs \\ %{}) do
    case Posts.get_post(post_id) do
      {:ok, post} ->
        offer_attrs = Map.merge(attrs, %{
          "post_id" => post_id,
          "offerer_id" => offerer_id,
          "receiver_id" => post.user_id,
          "original_price" => post.price,
          "currency" => post.currency,
          "status" => "pending"
        })

        create_offer_with_chat(offer_attrs)

      error -> error
    end
  end

  @doc """
  Создать предложение с собственной ценой.
  """
  def make_counter_offer(post_id, offerer_id, offered_price, attrs \\ %{}) do
    case Posts.get_post(post_id) do
      {:ok, post} ->
        offer_attrs = Map.merge(attrs, %{
          "post_id" => post_id,
          "offerer_id" => offerer_id,
          "receiver_id" => post.user_id,
          "original_price" => post.price,
          "offered_price" => offered_price,
          "currency" => post.currency,
          "status" => "pending"
        })

        create_offer_with_chat(offer_attrs)

      error -> error
    end
  end

  @doc """
  Принять предложение.
  """
  def accept_offer(offer_id, user_id) do
    case get_offer(offer_id) do
      {:ok, offer} ->
        if offer.receiver_id == user_id and offer.status == "pending" do
          offer
          |> Offer.changeset(%{
            status: "accepted",
            accepted_at: NaiveDateTime.utc_now()
          })
          |> Repo.update()
          |> case do
            {:ok, updated_offer} ->
              # Отклоняем все другие предложения на этот пост
              decline_other_offers(offer.post_id, offer.id)
              {:ok, updated_offer}

            error -> error
          end
        else
          {:error, "Cannot accept this offer"}
        end

      error -> error
    end
  end

  @doc """
  Отклонить предложение.
  """
  def decline_offer(offer_id, user_id, reason \\ nil) do
    case get_offer(offer_id) do
      {:ok, offer} ->
        if offer.receiver_id == user_id and offer.status == "pending" do
          offer
          |> Offer.changeset(%{status: "declined"})
          |> Repo.update()
        else
          {:error, "Cannot decline this offer"}
        end

      error -> error
    end
  end

  @doc """
  Отметить работу как завершенную.
  """
  def complete_offer(offer_id, user_id) do
    case get_offer(offer_id) do
      {:ok, offer} ->
        if (offer.receiver_id == user_id or offer.offerer_id == user_id) and
           offer.status == "accepted" do
          offer
          |> Offer.changeset(%{
            status: "completed",
            completed_at: NaiveDateTime.utc_now()
          })
          |> Repo.update()
        else
          {:error, "Cannot complete this offer"}
        end

      error -> error
    end
  end

  @doc """
  Получить предложение по ID.
  """
  def get_offer(id) do
    case Repo.get(Offer, id) do
      nil -> {:error, :not_found}
      offer -> {:ok, Repo.preload(offer, [:post, :offerer, :receiver, :conversation])}
    end
  end

  @doc """
  Получить все предложения для поста.
  """
  def list_post_offers(post_id) do
    Offer
    |> where([o], o.post_id == ^post_id)
    |> order_by(desc: :inserted_at)
    |> preload([:offerer, :conversation])
    |> Repo.all()
  end

  @doc """
  Получить предложения пользователя (сделанные им).
  """
  def list_user_offers(user_id) do
    Offer
    |> where([o], o.offerer_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> preload([:post, :receiver, :conversation])
    |> Repo.all()
  end

  @doc """
  Получить предложения полученные пользователем.
  """
  def list_received_offers(user_id) do
    Offer
    |> where([o], o.receiver_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> preload([:post, :offerer, :conversation])
    |> Repo.all()
  end

  # ===============================
  # ПРИВАТНЫЕ ФУНКЦИИ
  # ===============================

  defp create_offer_with_chat(attrs) do
    Repo.transaction(fn ->
      # 1. Создаем предложение
      offer = %Offer{}
      |> Offer.changeset(attrs)
      |> Repo.insert!()

      # 2. Создаем чат между участниками
      conversation = Chat.start_conversation(
        offer.post_id,
        offer.receiver_id,
        offer.offerer_id
      )

      case conversation do
        {:ok, conv} ->
          # 3. Связываем предложение с чатом
          offer
          |> Offer.changeset(%{conversation_id: conv.id})
          |> Repo.update!()
          |> Repo.preload([:post, :offerer, :receiver, :conversation])

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  defp decline_other_offers(post_id, accepted_offer_id) do
    Offer
    |> where([o], o.post_id == ^post_id and o.id != ^accepted_offer_id and o.status == "pending")
    |> Repo.update_all(set: [status: "declined", updated_at: NaiveDateTime.utc_now()])
  end
end
