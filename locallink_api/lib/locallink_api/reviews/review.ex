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

    # Связи - ИСПРАВЛЕНО: правильный алиас
    belongs_to :reviewer, LocallinkApi.User    # КТО оставил отзыв
    belongs_to :reviewee, LocallinkApi.User    # О КОМ отзыв
    belongs_to :post, LocallinkApi.Post        # За КАКУЮ работу/событие

    # Метаданные
    field :review_type, :string                # "work_completed", "event_attended", "help_provided"
    field :is_mutual, :boolean, default: false # Оставили ли оба отзыва?

    timestamps()
  end

  @valid_review_types ["work_completed", "event_attended", "help_provided"]

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [
      :rating, :comment, :work_quality, :communication,
      :timeliness, :would_recommend, :reviewer_id, :reviewee_id,
      :post_id, :review_type
    ])
    |> validate_required([:rating, :reviewer_id, :reviewee_id, :post_id])
    |> validate_inclusion(:rating, 1..5, message: "must be between 1 and 5")
    |> validate_inclusion(:work_quality, 1..5, message: "must be between 1 and 5")
    |> validate_inclusion(:communication, 1..5, message: "must be between 1 and 5")
    |> validate_inclusion(:timeliness, 1..5, message: "must be between 1 and 5")
    |> validate_inclusion(:review_type, @valid_review_types)
    |> validate_length(:comment, max: 500)
    |> validate_not_self_review()
    |> unique_constraint([:reviewer_id, :reviewee_id, :post_id],
         message: "You have already reviewed this user for this post")
    |> foreign_key_constraint(:reviewer_id)
    |> foreign_key_constraint(:reviewee_id)
    |> foreign_key_constraint(:post_id)
    |> set_default_values()
  end

  # Нельзя оставить отзыв самому себе
  defp validate_not_self_review(changeset) do
    reviewer_id = get_change(changeset, :reviewer_id)
    reviewee_id = get_change(changeset, :reviewee_id)

    if reviewer_id && reviewee_id && reviewer_id == reviewee_id do
      add_error(changeset, :reviewee_id, "cannot review yourself")
    else
      changeset
    end
  end

  # Устанавливаем значения по умолчанию
  defp set_default_values(changeset) do
    changeset
    |> set_default_if_nil(:work_quality, :rating)
    |> set_default_if_nil(:communication, :rating)
    |> set_default_if_nil(:timeliness, :rating)
    |> set_default_if_nil(:review_type, "work_completed")
    |> set_default_if_nil(:would_recommend, fn -> get_change(changeset, :rating, 3) >= 4 end)
  end

  # Вспомогательная функция для установки значений по умолчанию
  defp set_default_if_nil(changeset, field, default_field) when is_atom(default_field) do
    if get_change(changeset, field) == nil do
      default_value = get_change(changeset, default_field) || get_field(changeset, default_field)
      if default_value, do: put_change(changeset, field, default_value), else: changeset
    else
      changeset
    end
  end

  defp set_default_if_nil(changeset, field, default_value) when is_function(default_value) do
    if get_change(changeset, field) == nil do
      put_change(changeset, field, default_value.())
    else
      changeset
    end
  end

  defp set_default_if_nil(changeset, field, default_value) do
    if get_change(changeset, field) == nil do
      put_change(changeset, field, default_value)
    else
      changeset
    end
  end
end
