defmodule LocallinkApiWeb.OfferController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Offers
  alias LocallinkApi.Guardian

  action_fallback LocallinkApiWeb.FallbackController

  @doc "GET /api/v1/posts/:post_id/offers"
  def list_for_post(conn, %{"post_id" => post_id}) do
    user = Guardian.Plug.current_resource(conn)

    # если нужно фильтровать по current_user, можно передать user.id
    offers = Offers.list_offers_for_post(post_id)

    conn
    |> put_status(:ok)
    |> json(%{offers: Enum.map(offers, &format_offer/1)})
  end

  @doc "POST /api/v1/posts/:post_id/offers/accept-price"
  def accept_original_price(conn, %{"post_id" => pid} = params) do
    user = Guardian.Plug.current_resource(conn)
    message = Map.get(params, "message", "")

    case Offers.accept_original_price(pid, user.id, %{"message" => message}) do
      {:ok, offer} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Offer created", offer: format_offer(offer)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(cs)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc "POST /api/v1/posts/:post_id/offers/counter-offer"
  def make_counter_offer(conn, %{"post_id" => pid, "offered_price" => price} = params) do
    user = Guardian.Plug.current_resource(conn)
    message = Map.get(params, "message", "")

    case Offers.make_counter_offer(pid, user.id, price, %{"message" => message}) do
      {:ok, offer} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Counter-offer created", offer: format_offer(offer)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(cs)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc "PUT /api/v1/offers/:id/accept"
  def accept_offer(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    case Offers.accept_offer(id, user.id) do
      {:ok, offer} ->
        json(conn, %{message: "Offer accepted", offer: format_offer(offer)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(cs)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc "PUT /api/v1/offers/:id/decline"
  def decline_offer(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    case Offers.decline_offer(id, user.id) do
      {:ok, offer} ->
        json(conn, %{message: "Offer declined", offer: format_offer(offer)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(cs)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc "PUT /api/v1/offers/:id/complete"
  def complete_offer(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    case Offers.complete_offer(id, user.id) do
      {:ok, offer} ->
        json(conn, %{message: "Work completed", offer: format_offer(offer)})

      {:error, %Ecto.Changeset{} = cs} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(cs)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  # ——————————————————————————————————————————————————————————————————————————
  # Вспомогательные функции

  defp format_offer(offer) do
    %{
      id: offer.id,
      original_price: offer.original_price,
      offered_price: offer.offered_price,
      currency: offer.currency,
      message: offer.message,
      status: offer.status,
      post_id: offer.post_id,
      offerer_id: offer.offerer_id,
      receiver_id: offer.receiver_id,
      inserted_at: offer.inserted_at,
      updated_at: offer.updated_at
    }
  end

  defp translate_errors(%Ecto.Changeset{} = cs) do
    Ecto.Changeset.traverse_errors(cs, &translate_error/1)
  end
  defp translate_errors(_), do: %{}

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end
end
