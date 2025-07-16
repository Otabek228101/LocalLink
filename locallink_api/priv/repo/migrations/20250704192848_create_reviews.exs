defmodule LocallinkApi.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:reviews, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Основные поля
      add :rating, :integer, null: false
      add :comment, :text
      add :work_quality, :integer
      add :communication, :integer
      add :timeliness, :integer
      add :would_recommend, :boolean, default: true
      add :review_type, :string, default: "work_completed"
      add :is_mutual, :boolean, default: false

      # Связи
      add :reviewer_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :reviewee_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :post_id, references(:posts, on_delete: :delete_all, type: :binary_id), null: false

      timestamps()
    end

    # Индексы для производительности
    create index(:reviews, [:reviewee_id])
    create index(:reviews, [:reviewer_id])
    create index(:reviews, [:post_id])
    create index(:reviews, [:rating])
    create index(:reviews, [:inserted_at])

    # Уникальное ограничение - один отзыв на пару пользователь-пост
    create unique_index(:reviews, [:reviewer_id, :reviewee_id, :post_id])

    # Проверочные ограничения
    create constraint(:reviews, :rating_range, check: "rating >= 1 AND rating <= 5")
    create constraint(:reviews, :work_quality_range, check: "work_quality IS NULL OR (work_quality >= 1 AND work_quality <= 5)")
    create constraint(:reviews, :communication_range, check: "communication IS NULL OR (communication >= 1 AND communication <= 5)")
    create constraint(:reviews, :timeliness_range, check: "timeliness IS NULL OR (timeliness >= 1 AND timeliness <= 5)")
    create constraint(:reviews, :different_users, check: "reviewer_id != reviewee_id")
  end
end
