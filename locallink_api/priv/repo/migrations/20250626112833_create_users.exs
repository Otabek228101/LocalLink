defmodule LocallinkApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :phone, :string
      add :location, :string
      add :skills, :text
      add :availability, :string
      add :is_verified, :boolean, default: false
      add :profile_image_url, :string
      add :rating, :decimal, precision: 3, scale: 2, default: 0.0
      add :total_jobs_completed, :integer, default: 0

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:location])
  end
end
