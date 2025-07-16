defmodule LocallinkApiWeb.ReviewController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Reviews
  alias LocallinkApi.Guardian
  alias LocallinkApi.Repo

  require Logger

  action_fallback LocallinkApiWeb.FallbackController

  @doc """
  POST /api/v1/reviews
  Создать отзыв о пользователе за выполненную работу.
  """
  def create(conn, %{"review" => review_params}) do
    reviewer = Guardian.Plug.current_resource(conn)

    reviewee_id = review_params["reviewee_id"]
    post_id = review_params["post_id"]

    Logger.info("Creating review: reviewer_id=#{reviewer.id}, reviewee_id=#{reviewee_id}, post_id=#{post_id}")

    # Валидация входных данных
    with {:ok, reviewee_id} <- validate_uuid(reviewee_id, "reviewee_id"),
         {:ok, post_id} <- validate_uuid(post_id, "post_id"),
         {:ok, validated_params} <- validate_review_params(review_params),
         true <- Reviews.can_leave_review?(reviewer.id, reviewee_id, post_id) do

      case Reviews.create_review(reviewer.id, reviewee_id, post_id, validated_params) do
        {:ok, review} ->
          review = Repo.preload(review, [:reviewer, :reviewee, :post])
          Logger.info("Review created successfully: #{review.id}")

          conn
          |> put_status(:created)
          |> json(%{
            message: "Review created successfully",
            review: format_review(review)
          })

        {:error, changeset} ->
          Logger.warn("Review creation failed: #{inspect(changeset.errors)}")
          {:error, changeset}

        {:error, reason} ->
          Logger.error("Review creation failed: #{reason}")
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.warn("Review validation failed: #{reason}")
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})

      false ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: "Cannot leave review",
          details: "Review already exists or invalid conditions"
        })
    end
  end

  def create(conn, params) do
    Logger.warn("Invalid review creation params: #{inspect(params)}")
    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Invalid request format",
      expected: %{review: %{reviewee_id: "string", post_id: "string", rating: "integer"}},
      received: params
    })
  end

  @doc """
  GET /api/v1/users/:user_id/reviews
  Получить все отзывы о пользователе.
  """
  def user_reviews(conn, %{"user_id" => user_id}) do
    with {:ok, user_id} <- validate_uuid(user_id, "user_id") do
      try do
        reviews = Reviews.list_user_reviews(user_id)
        stats = Reviews.get_user_review_stats(user_id)

        conn
        |> json(%{
          reviews: Enum.map(reviews, &format_review/1),
          stats: stats
        })
      rescue
        error ->
          Logger.error("Error fetching user reviews: #{inspect(error)}")
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Failed to fetch reviews"})
      end
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  GET /api/v1/users/:user_id/reviews/detailed
  Получить детальную статистику отзывов.
  """
  def detailed_user_reviews(conn, %{"user_id" => user_id}) do
    with {:ok, user_id} <- validate_uuid(user_id, "user_id") do
      try do
        detailed_stats = Reviews.get_detailed_review_stats(user_id)

        conn
        |> json(%{
          stats: detailed_stats
        })
      rescue
        error ->
          Logger.error("Error fetching detailed reviews: #{inspect(error)}")
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Failed to fetch detailed reviews"})
      end
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  GET /api/v1/reviews/my
  Получить отзывы, оставленные текущим пользователем.
  """
  def my_reviews(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    try do
      reviews = Reviews.list_reviews_by_user(user.id)

      conn
      |> json(%{
        reviews: Enum.map(reviews, &format_review/1)
      })
    rescue
      error ->
        Logger.error("Error fetching my reviews: #{inspect(error)}")
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to fetch your reviews"})
    end
  end

  # ===============================
  # ПРИВАТНЫЕ ФУНКЦИИ
  # ===============================

  # Валидация UUID
  defp validate_uuid(uuid_string, field_name) do
    case Ecto.UUID.cast(uuid_string) do
      {:ok, uuid} -> {:ok, uuid}
      :error -> {:error, "Invalid #{field_name} format - must be UUID"}
    end
  end

  # Валидация параметров отзыва
  defp validate_review_params(params) do
    required_fields = ["rating"]
    missing_fields = required_fields -- Map.keys(params)

    if missing_fields != [] do
      {:error, "Missing required fields: #{Enum.join(missing_fields, ", ")}"}
    else
      # Валидация рейтинга
      case validate_rating(params["rating"]) do
        {:ok, rating} ->
          validated_params = Map.put(params, "rating", rating)

          # Валидация опциональных полей
          validated_params = validated_params
          |> validate_optional_rating("work_quality")
          |> validate_optional_rating("communication")
          |> validate_optional_rating("timeliness")
          |> validate_optional_boolean("would_recommend")

          {:ok, validated_params}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Валидация рейтинга
  defp validate_rating(rating) when is_integer(rating) and rating >= 1 and rating <= 5 do
    {:ok, rating}
  end
  defp validate_rating(rating) when is_binary(rating) do
    case Integer.parse(rating) do
      {int_rating, ""} when int_rating >= 1 and int_rating <= 5 -> {:ok, int_rating}
      _ -> {:error, "Rating must be integer between 1 and 5"}
    end
  end
  defp validate_rating(_), do: {:error, "Rating must be integer between 1 and 5"}

  # Валидация опционального рейтинга
  defp validate_optional_rating(params, field) do
    case Map.get(params, field) do
      nil -> params
      value when is_integer(value) and value >= 1 and value <= 5 -> params
      value when is_binary(value) ->
        case Integer.parse(value) do
          {int_value, ""} when int_value >= 1 and int_value <= 5 ->
            Map.put(params, field, int_value)
          _ ->
            Map.delete(params, field)
        end
      _ -> Map.delete(params, field)
    end
  end

  # Валидация опционального boolean
  defp validate_optional_boolean(params, field) do
    case Map.get(params, field) do
      nil -> params
      value when is_boolean(value) -> params
      "true" -> Map.put(params, field, true)
      "false" -> Map.put(params, field, false)
      _ -> Map.delete(params, field)
    end
  end

  # Форматирование отзыва для JSON
  defp format_review(review) do
    %{
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      work_quality: review.work_quality,
      communication: review.communication,
      timeliness: review.timeliness,
      would_recommend: review.would_recommend,
      review_type: review.review_type,
      inserted_at: review.inserted_at,
      reviewer: format_user(review.reviewer),
      reviewee: format_user(review.reviewee),
      post: format_post(review.post)
    }
  end

  # Форматирование пользователя
  defp format_user(nil), do: nil
  defp format_user(user) do
    %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      rating: user.rating
    }
  end

  # Форматирование поста
  defp format_post(nil), do: nil
  defp format_post(post) do
    %{
      id: post.id,
      title: post.title,
      category: post.category
    }
  end
end
