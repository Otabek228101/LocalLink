defmodule LocallinkApi.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def up do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :title, :string, null: false
      add :description, :text, null: false
      add :category, :string, null: false
      add :post_type, :string, null: false
      add :location, :string, null: false
      add :urgency, :string, default: "flexible"
      add :price, :decimal, precision: 10, scale: 2
      add :currency, :string, default: "UZS"
      add :skills_required, :text
      add :duration_estimate, :string
      add :max_distance_km, :integer, default: 10
      add :is_active, :boolean, default: true
      add :expires_at, :utc_datetime_usec
      add :images, :text
      add :contact_preference, :string, default: "app"

      add :coordinates, :geometry
      add :max_participants, :integer
      add :current_participants, :integer, default: 0
      add :participants, {:array, :binary_id}, default: []
      add :event_date, :utc_datetime_usec

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    # Индексы
    create index(:posts, [:user_id])
    create index(:posts, [:category, :is_active])
    create index(:posts, [:post_type, :is_active])
    create index(:posts, [:location, :is_active])
    create index(:posts, [:expires_at])
    create index(:posts, [:event_date])
    create index(:posts, [:current_participants])
    create index(:posts, [:max_participants])
    create index(:posts, [:inserted_at])
    create index(:posts, [:urgency])

    # Гео-индексы (через EXECUTE, т.к. Ecto не знает о GIST-подразделении)
    execute "CREATE INDEX IF NOT EXISTS posts_coordinates_gist_idx ON posts USING GIST (coordinates)"
    execute """
    CREATE INDEX IF NOT EXISTS posts_active_coordinates_gist_idx
    ON posts USING GIST (coordinates)
    WHERE is_active = true
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS posts_active_coordinates_gist_idx"
    execute "DROP INDEX IF EXISTS posts_coordinates_gist_idx"

    drop index(:posts, [:urgency])
    drop index(:posts, [:inserted_at])
    drop index(:posts, [:max_participants])
    drop index(:posts, [:current_participants])
    drop index(:posts, [:event_date])
    drop index(:posts, [:expires_at])
    drop index(:posts, [:location, :is_active])
    drop index(:posts, [:post_type, :is_active])
    drop index(:posts, [:category, :is_active])
    drop index(:posts, [:user_id])

    drop table(:posts)
  end
end
