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
    # Проверяем что пользователь не оставляет отзыв сам себе
    if reviewer_id == reviewee_id do
      {:error, "Cannot review yourself"}
    else
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
          Task.start(fn -> update_user_rating(reviewee_id) end)
          {:ok, review}

        error -> error
      end
    end
  end

  @doc """
  Получает все отзывы О пользователе (полученные им).
  """
  def list_user_reviews(user_id) do
    Review
    |> where([r], r.reviewee_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> preload([:reviewer, :reviewee, :post])
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
    cond do
      reviewer_id == reviewee_id ->
        false

      true ->
        # Проверяем, что отзыва еще нет
        existing = Repo.get_by(Review,
          reviewer_id: reviewer_id,
          reviewee_id: reviewee_id,
          post_id: post_id
        )
        is_nil(existing)
    end
  end

  @doc """
  Получает статистику отзывов пользователя с безопасной обработкой nil.
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
        default_stats()

      %{total_reviews: 0} ->
        default_stats()

      stats ->
        %{
          total_reviews: stats.total_reviews || 0,
          average_rating: safe_round_rating(stats.average_rating),
          average_work_quality: safe_round_rating(stats.average_work_quality),
          average_communication: safe_round_rating(stats.average_communication),
          average_timeliness: safe_round_rating(stats.average_timeliness),
          recommendation_rate: safe_round_percentage(stats.recommendation_rate)
        }
    end
  end

  # ===============================
  # ПРИВАТНЫЕ ФУНКЦИИ
  # ===============================

  # Безопасное округление рейтинга
  defp safe_round_rating(nil), do: 0.0
  defp safe_round_rating(rating) when is_number(rating) do
    rating
    |> Float.round(1)
    |> max(0.0)
    |> min(5.0)
  end
  defp safe_round_rating(_), do: 0.0

  # Безопасное округление процентов
  defp safe_round_percentage(nil), do: 0.0
  defp safe_round_percentage(rate) when is_number(rate) do
    (rate * 100)
    |> Float.round(1)
    |> max(0.0)
    |> min(100.0)
  end
  defp safe_round_percentage(_), do: 0.0

  # Статистика по умолчанию
  defp default_stats do
    %{
      total_reviews: 0,
      average_rating: 0.0,
      average_work_quality: 0.0,
      average_communication: 0.0,
      average_timeliness: 0.0,
      recommendation_rate: 0.0
    }
  end

  # Обновляет средний рейтинг пользователя в его профиле
  defp update_user_rating(user_id) do
    stats = get_user_review_stats(user_id)

    from(u in User, where: u.id == ^user_id)
    |> Repo.update_all(set: [
      rating: Decimal.new(to_string(stats.average_rating)),
      total_jobs_completed: stats.total_reviews,
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    ])
  end
end
