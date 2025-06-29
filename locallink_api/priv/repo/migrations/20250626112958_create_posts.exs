defmodule LocallinkApi.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :description, :text, null: false
      add :category, :string, null: false
      add :post_type, :string, null: false
      add :location, :string, null: false
      add :urgency, :string, null: false
      add :price, :decimal, precision: 10, scale: 2
      add :currency, :string, default: "UZS"
      add :skills_required, :text
      add :duration_estimate, :string
      add :max_distance_km, :integer, default: 10
      add :is_active, :boolean, default: true, null: false
      add :expires_at, :naive_datetime
      add :images, :text
      add :contact_preference, :string, default: "app"
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:posts, [:user_id])
    create index(:posts, [:category])
    create index(:posts, [:location])
    create index(:posts, [:is_active])
    create index(:posts, [:inserted_at])
  end
end
