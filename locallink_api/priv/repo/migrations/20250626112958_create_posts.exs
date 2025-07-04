defmodule LocallinkApi.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def up do
    # Включаем PostGIS расширение для геолокации
    execute "CREATE EXTENSION IF NOT EXISTS postgis"

    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Основные поля
      add :title, :string, null: false
      add :description, :text, null: false
      add :category, :string, null: false
      add :post_type, :string, null: false
      add :location, :string, null: false
      add :urgency, :string, default: "flexible"

      # Финансовые поля
      add :price, :decimal, precision: 10, scale: 2
      add :currency, :string, default: "UZS"

      # Дополнительная информация
      add :skills_required, :text
      add :duration_estimate, :string
      add :max_distance_km, :integer, default: 10
      add :is_active, :boolean, default: true
      add :expires_at, :naive_datetime
      add :images, :text
      add :contact_preference, :string, default: "app"

      # ГЕОЛОКАЦИЯ (PostGIS)
      add :coordinates, :geometry

      # ПОЛЯ ДЛЯ СОБЫТИЙ
      add :max_participants, :integer
      add :current_participants, :integer, default: 0
      add :participants, {:array, :binary_id}, default: []
      add :event_date, :naive_datetime

      # Связь с пользователем
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    # Базовые индексы для поиска
    create index(:posts, [:user_id])
    create index(:posts, [:category])
    create index(:posts, [:post_type])
    create index(:posts, [:location])
    create index(:posts, [:is_active])
    create index(:posts, [:inserted_at])
    create index(:posts, [:urgency])
    create index(:posts, [:expires_at])

    # Композитные индексы для производительности
    create index(:posts, [:category, :is_active])
    create index(:posts, [:post_type, :is_active])
    create index(:posts, [:location, :is_active])
    create index(:posts, [:user_id, :is_active])

    # ===============================
    # ИНДЕКСЫ ДЛЯ СОБЫТИЙ
    # ===============================

    # Поиск событий
    create index(:posts, [:event_date])
    create index(:posts, [:max_participants])
    create index(:posts, [:current_participants])

    # Композитные индексы для событий
    create index(:posts, [:category, :event_date],
      name: :posts_events_by_date_index)
    create index(:posts, [:category, :is_active, :event_date],
      name: :posts_active_events_index)
    create index(:posts, [:category, :current_participants, :max_participants],
      name: :posts_available_events_index)

    # ===============================
    # ГЕОПРОСТРАНСТВЕННЫЕ ИНДЕКСЫ
    # ===============================

    # Пространственный индекс для быстрого поиска по координатам
    execute "CREATE INDEX posts_coordinates_gist_idx ON posts USING GIST (coordinates)"

    # Композитный индекс для поиска активных постов по геолокации
    execute """
    CREATE INDEX posts_location_active_idx
    ON posts USING GIST (coordinates, is_active)
    WHERE is_active = true
    """
  end

  def down do
    # Удаляем пространственные индексы
    execute "DROP INDEX IF EXISTS posts_coordinates_gist_idx"
    execute "DROP INDEX IF EXISTS posts_location_active_idx"

    # Удаляем обычные индексы
    drop index(:posts, [:user_id])
    drop index(:posts, [:category])
    drop index(:posts, [:post_type])
    drop index(:posts, [:location])
    drop index(:posts, [:is_active])
    drop index(:posts, [:inserted_at])
    drop index(:posts, [:urgency])
    drop index(:posts, [:expires_at])
    drop index(:posts, [:event_date])
    drop index(:posts, [:max_participants])
    drop index(:posts, [:current_participants])

    # Удаляем композитные индексы
    drop index(:posts, :posts_events_by_date_index)
    drop index(:posts, :posts_active_events_index)
    drop index(:posts, :posts_available_events_index)
    drop index(:posts, [:category, :is_active])
    drop index(:posts, [:post_type, :is_active])
    drop index(:posts, [:location, :is_active])
    drop index(:posts, [:user_id, :is_active])

    # Удаляем таблицу
    drop table(:posts)

    # Удаляем PostGIS расширение (осторожно!)
    execute "DROP EXTENSION IF EXISTS postgis CASCADE"
  end
end
