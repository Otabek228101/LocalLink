defmodule LocallinkApi.Reviews.Review do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "reviews" do
    # Основные поля
    field :rating, :integer                    # 1-5 звезд (обязательно)
    field :comment, :string                    # Текст отзыва (опционально)
    field :work_quality, :integer              # Качество работы 1-5
    field :communication, :integer             # Общение 1-5
    field :timeliness, :integer                # Пунктуальность 1-5
    field :would_recommend, :boolean           # Рекомендую ли?

    # Связи
    belongs_to :reviewer, LocallinkApi.User    # КТО оставил отзыв
    belongs_to :reviewee, LocallinkApi.User    # О КОМ отзыв
    belongs_to :post, LocallinkApi.Post        # За КАКУЮ работу/событие

    # Метаданные
    field :review_type, :string                # "work_completed", "event_attended", "help_provided"
    field :is_mutual, :boolean, default: false # Оставили ли оба отзыва?

    timestamps()
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [
      :rating, :comment, :work_quality, :communication,
      :timeliness, :would_recommend, :reviewer_id, :reviewee_id,
      :post_id, :review_type
    ])
    |> validate_required([:rating, :reviewer_id, :reviewee_id, :post_id])
    |> validate_inclusion(:rating, 1..5)
    |> validate_inclusion(:work_quality, 1..5)
    |> validate_inclusion(:communication, 1..5)
    |> validate_inclusion(:timeliness, 1..5)
    |> validate_inclusion(:review_type, ["work_completed", "event_attended", "help_provided"])
    |> validate_length(:comment, max: 500)
    |> validate_not_self_review()
    |> unique_constraint([:reviewer_id, :reviewee_id, :post_id])
  end

  # Нельзя оставить отзыв самому себе
  defp validate_not_self_review(changeset) do
    reviewer_id = get_change(changeset, :reviewer_id)
    reviewee_id = get_change(changeset, :reviewee_id)

    if reviewer_id == reviewee_id do
      add_error(changeset, :reviewee_id, "cannot review yourself")
    else
      changeset
    end
  end
end
