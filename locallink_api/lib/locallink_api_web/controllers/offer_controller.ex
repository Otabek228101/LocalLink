# lib/locallink_api_web/controllers/offer_controller.ex
defmodule LocallinkApiWeb.OfferController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Offers
  alias LocallinkApi.Guardian

  action_fallback LocallinkApiWeb.FallbackController

  @doc """
  POST /api/v1/posts/:post_id/offers/accept-price
  Принять оригинальную цену из поста.
  """
  def accept_original_price(conn, %{"post_id" => post_id, "message" => message}) do
    user = Guardian.Plug.current_resource(conn)

    case Offers.accept_original_price(post_id, user.id, %{"message" => message}) do
      {:ok, offer} ->
        conn
        |> put_status(:created)
        |> json(%{
          message: "Offer created successfully",
          offer: format_offer(offer),
          conversation_id: offer.conversation_id
        })

      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  POST /api/v1/posts/:post_id/offers/counter-offer
  Предложить свою цену.
  """
  def make_counter_offer(conn, %{
    "post_id" => post_id,
    "offered_price" => offered_price,
    "message" => message
  }) do
    user = Guardian.Plug.current_resource(conn)

    case Offers.make_counter_offer(post_id, user.id, offered_price, %{"message" => message}) do
      {:ok, offer} ->
        conn
        |> put_status(:created)
        |> json(%{
          message: "Counter-offer created successfully",
          offer: format_offer(offer),
          conversation_id: offer.conversation_id
        })

      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  PUT /api/v1/offers/:id/accept
  Принять предложение.
  """
  def accept_offer(conn, %{"id" => offer_id}) do
    user = Guardian.Plug.current_resource(conn)

    case Offers.accept_offer(offer_id, user.id) do
      {:ok, offer} ->
        json(conn, %{
          message: "Offer accepted successfully",
          offer: format_offer(offer)
        })

      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  PUT /api/v1/offers/:id/decline
  Отклонить предложение.
  """
  def decline_offer(conn, %{"id" => offer_id}) do
    user = Guardian.Plug.current_resource(conn)

    case Offers.decline_offer(offer_id, user.id) do
      {:ok, offer} ->
        json(conn, %{
          message: "Offer declined",
          offer: format_offer(offer)
        })

      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  PUT /api/v1/offers/:id/complete
  Завершить работу.
  """
  def complete_offer(conn, %{"id" => offer_id}) do
    user = Guardian.Plug.current_resource(conn)

    case Offers.complete_offer(offer_id, user.id) do
      {:ok, offer} ->
        json(conn, %{
          message: "Work completed successfully",
          offer: format_offer(offer)
        })

      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  GET /api/v1/posts/:post_id/offers
  Получить все предложения для поста.
  """
  def list_post_offers(conn, %{"post_id" => post_id}) do
    offers = Offers.list_post_offers(post_id)

    json(conn, %{
      offers: Enum.map(offers, &format_offer/1)
    })
  end

  @doc """
  GET /api/v1/my-offers
  Мои предложения (сделанные мной).
  """
  def my_offers(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    offers = Offers.list_user_offers(user.id)

    json(conn, %{
      offers: Enum.map(offers, &format_offer/1)
    })
  end

  @doc """
  GET /api/v1/received-offers
  Предложения полученные мной.
  """
  def received_offers(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    offers = Offers.list_received_offers(user.id)

    json(conn, %{
      offers: Enum.map(offers, &format_offer/1)
    })
  end

  # ===============================
  # HELPER FUNCTIONS
  # ===============================

  defp format_offer(offer) do
    %{
      id: offer.id,
      original_price: offer.original_price,
      offered_price: offer.offered_price,
      currency: offer.currency,
      message: offer.message,
      status: offer.status,
      expires_at: offer.expires_at,
      estimated_completion: offer.estimated_completion,
      accepted_at: offer.accepted_at,
      completed_at: offer.completed_at,
      conversation_id: offer.conversation_id,
      inserted_at: offer.inserted_at,

      # Информация о посте
      post: format_post_summary(offer.post),

      # Информация об исполнителе
      offerer: format_user_summary(offer.offerer),

      # Информация о заказчике
      receiver: format_user_summary(offer.receiver),

      # Удобные поля для фронтенда
      is_counter_offer: !is_nil(offer.offered_price) &&
                       !is_nil(offer.original_price) &&
                       offer.offered_price != offer.original_price,

      final_price: offer.offered_price || offer.original_price,

      savings: if(offer.offered_price && offer.original_price,
        do: Decimal.sub(offer.original_price, offer.offered_price),
        else: nil)
    }
  end

  defp format_post_summary(nil), do: nil
  defp format_post_summary(post) do
    %{
      id: post.id,
      title: post.title,
      category: post.category,
      location: post.location
    }
  end

  defp format_user_summary(nil), do: nil
  defp format_user_summary(user) do
    %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      rating: user.rating,
      total_jobs_completed: user.total_jobs_completed,
      profile_image_url: user.profile_image_url
    }
  end
end
