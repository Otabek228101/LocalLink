defmodule LocallinkApi.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all)
      add :user1_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :user2_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :started_by_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:conversations, [:post_id, :user1_id, :user2_id], name: :conversations_post_user1_user2_index)
  end
end
