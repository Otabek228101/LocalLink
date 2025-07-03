defmodule LocallinkApi.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :text
      add :read, :boolean, default: false

      add :conversation_id, references(:conversations, type: :binary_id, on_delete: :delete_all)
      add :sender_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:sender_id])
  end
end
