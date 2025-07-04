defmodule LocallinkApiWeb.ReviewController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Reviews
  alias LocallinkApi.Guardian
  alias LocallinkApi.Repo

  action_fallback LocallinkApiWeb.FallbackController

  @doc """
  POST /api/v1/reviews
  Создать отзыв о пользователе за выполненную работу.
  """
  def create(conn, %{"review" => review_params}) do
    reviewer = Guardian.Plug.current_resource(conn)

    reviewee_id = review_params["reviewee_id"]
    post_id = review_params["post_id"]

    # Проверяем право оставить отзыв
    unless Reviews.can_leave_review?(reviewer.id, reviewee_id, post_id) do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Review already exists"})
    else
      case Reviews.create_review(reviewer.id, reviewee_id, post_id, review_params) do
        {:ok, review} ->
          review = Repo.preload(review, [:reviewer, :reviewee, :post])

          conn
          |> put_status(:created)
          |> json(%{
            message: "Review created successfully",
            review: format_review(review)
          })

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  @doc """
  GET /api/v1/users/:user_id/reviews
  Получить все отзывы о пользователе.
  """
  def user_reviews(conn, %{"user_id" => user_id}) do
    reviews = Reviews.list_user_reviews(user_id)
    stats = Reviews.get_user_review_stats(user_id)

    conn
    |> json(%{
      reviews: Enum.map(reviews, &format_review/1),
      stats: stats
    })
  end

  @doc """
  GET /api/v1/my-reviews
  Получить отзывы, оставленные текущим пользователем.
  """
  def my_reviews(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    reviews = Reviews.list_reviews_by_user(user.id)

    conn
    |> json(%{
      reviews: Enum.map(reviews, &format_review/1)
    })
  end

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
      reviewer: %{
        id: review.reviewer.id,
        first_name: review.reviewer.first_name,
        last_name: review.reviewer.last_name
      },
      reviewee: %{
        id: review.reviewee.id,
        first_name: review.reviewee.first_name,
        last_name: review.reviewee.last_name
      },
      post: %{
        id: review.post.id,
        title: review.post.title
      }
    }
  end
end
