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
      add :is_verified, :boolean, default: false, null: false
      add :profile_image_url, :string
      add :rating, :decimal, precision: 3, scale: 2
      add :total_jobs_completed, :integer, default: 0, null: false

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
