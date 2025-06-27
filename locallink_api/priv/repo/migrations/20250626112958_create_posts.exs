defmodule LocallinkApi.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :description, :text
      add :category, :string
      add :location, :string
      add :urgency, :string
      add :price, :decimal
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:user_id])
  end
end
