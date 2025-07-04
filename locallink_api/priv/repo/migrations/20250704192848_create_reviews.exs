defmodule LocallinkApi.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:reviews, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Оценки
      add :rating, :integer, null: false
      add :work_quality, :integer
      add :communication, :integer
      add :timeliness, :integer

      # Контент
      add :comment, :text
      add :would_recommend, :boolean, default: true
      add :review_type, :string, null: false
      add :is_mutual, :boolean, default: false

      # Связи
      add :reviewer_id, references(:users, type: :binary_id), null: false
      add :reviewee_id, references(:users, type: :binary_id), null: false
      add :post_id, references(:posts, type: :binary_id), null: false

      timestamps()
    end

    # Индексы для быстрого поиска
    create index(:reviews, [:reviewee_id])                    # Отзывы О пользователе
    create index(:reviews, [:reviewer_id])                    # Отзывы ОТ пользователя
    create index(:reviews, [:post_id])                        # Отзывы по объявлению
    create index(:reviews, [:rating])                         # Сортировка по рейтингу

    # Уникальность: один человек может оставить только один отзыв другому за одну работу
    create unique_index(:reviews, [:reviewer_id, :reviewee_id, :post_id])
  end
end
