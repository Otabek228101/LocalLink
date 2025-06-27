defmodule LocallinkApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :password_hash, :string
      add :first_name, :string
      add :last_name, :string
      add :phone, :string
      add :location, :string
      add :skills, :text
      add :availability, :string
      add :inserted_at, :naive_datetime
      add :updated_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
  end
end
