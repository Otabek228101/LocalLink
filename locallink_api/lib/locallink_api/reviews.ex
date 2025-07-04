defmodule LocallinkApi.Reviews do
  @moduledoc """
  Контекст для управления отзывами пользователей.
  """

  import Ecto.Query, warn: false
  alias LocallinkApi.Repo
  alias LocallinkApi.Reviews.Review
  alias LocallinkApi.User

  @doc """
  Создает отзыв о пользователе за выполненную работу.
  """
  def create_review(reviewer_id, reviewee_id, post_id, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{
      "reviewer_id" => reviewer_id,
      "reviewee_id" => reviewee_id,
      "post_id" => post_id
    })

    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, review} ->
        # Обновляем средний рейтинг пользователя
        update_user_rating(reviewee_id)
        {:ok, review}

      error -> error
    end
  end

  @doc """
  Получает все отзывы О пользователе (полученные им).
  """
  def list_user_reviews(user_id) do
    Review
    |> where([r], r.reviewee_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> preload([:reviewer, :post])
    |> Repo.all()
  end

  @doc """
  Получает отзывы ОТ пользователя (оставленные им).
  """
  def list_reviews_by_user(user_id) do
    Review
    |> where([r], r.reviewer_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> preload([:reviewee, :post])
    |> Repo.all()
  end

  @doc """
  Проверяет, может ли пользователь оставить отзыв.
  """
  def can_leave_review?(reviewer_id, reviewee_id, post_id) do
    # Проверяем, что отзыва еще нет
    existing = Repo.get_by(Review,
      reviewer_id: reviewer_id,
      reviewee_id: reviewee_id,
      post_id: post_id
    )

    is_nil(existing)
  end

  @doc """
  Получает статистику отзывов пользователя.
  """
  def get_user_review_stats(user_id) do
    query = from r in Review,
      where: r.reviewee_id == ^user_id,
      select: %{
        total_reviews: count(r.id),
        average_rating: avg(r.rating),
        average_work_quality: avg(r.work_quality),
        average_communication: avg(r.communication),
        average_timeliness: avg(r.timeliness),
        recommendation_rate: avg(fragment("CASE WHEN ? THEN 1.0 ELSE 0.0 END", r.would_recommend))
      }

    case Repo.one(query) do
      nil ->
        %{
          total_reviews: 0,
          average_rating: 0.0,
          average_work_quality: 0.0,
          average_communication: 0.0,
          average_timeliness: 0.0,
          recommendation_rate: 0.0
        }

      stats ->
        stats
        |> Map.update(:average_rating, 0.0, &round_rating/1)
        |> Map.update(:average_work_quality, 0.0, &round_rating/1)
        |> Map.update(:average_communication, 0.0, &round_rating/1)
        |> Map.update(:average_timeliness, 0.0, &round_rating/1)
        |> Map.update(:recommendation_rate, 0.0, &(&1 * 100 |> Float.round(1)))
    end
  end

  # Обновляет средний рейтинг пользователя в его профиле
  defp update_user_rating(user_id) do
    stats = get_user_review_stats(user_id)

    from(u in User, where: u.id == ^user_id)
    |> Repo.update_all(set: [
      rating: stats.average_rating,
      total_jobs_completed: stats.total_reviews  # Количество выполненных работ
    ])
  end

  defp round_rating(nil), do: 0.0
  defp round_rating(rating) when is_float(rating), do: Float.round(rating, 1)
  defp round_rating(rating), do: rating
end
