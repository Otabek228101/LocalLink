defmodule LocallinkApi.Repo.Migrations.CreateConversationsAndMessages do
  use Ecto.Migration

  def change do
    # Таблица бесед
    create table(:conversations, primary_key: false) do
      add :id,             :binary_id, primary_key: true
      add :post_id,        references(:posts, type: :binary_id, on_delete: :delete_all), null: false
      add :user1_id,       references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :user2_id,       references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :started_by_id,  :binary_id, null: false

      timestamps()
    end

    # Уникальность: одна беседа между теми же участниками по тому же посту
    create unique_index(
      :conversations,
      [:post_id, :user1_id, :user2_id],
      name: :conversations_post_user1_user2_index
    )

    # Таблица сообщений
    create table(:messages, primary_key: false) do
      add :id,              :binary_id, primary_key: true
      add :body,            :text, null: false
      add :read,            :boolean, default: false, null: false
      add :conversation_id, references(:conversations, type: :binary_id, on_delete: :delete_all), null: false
      add :sender_id,       references(:users, type: :binary_id, on_delete: :nothing), null: false

      timestamps()
    end

    # Индексы для быстрого поиска по беседам и отправителю
    create index(:messages, [:conversation_id])
    create index(:messages, [:sender_id])
  end
end
