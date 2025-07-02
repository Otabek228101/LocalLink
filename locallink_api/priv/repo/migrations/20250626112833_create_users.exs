defmodule LocallinkApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :password_hash, :string
      add :first_name, :string
      add :last_name, :string
      add :phone, :string
      add :location, :string
      add :skills, :string
      add :availability, :string
      add :is_verified, :boolean, default: false
      add :profile_image_url, :string
      add :rating, :decimal
      add :total_jobs_completed, :integer, default: 0

      timestamps()
    end

    create unique_index(:users, [:email])
  end

end
