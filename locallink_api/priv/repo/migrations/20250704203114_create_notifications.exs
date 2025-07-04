defmodule LocallinkApi.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Кому и о чем
      add :user_id, references(:users, type: :binary_id), null: false
      add :post_id, references(:posts, type: :binary_id), null: false

      # Содержание уведомления
      add :title, :string, null: false                    # "Работа рядом с вами"
      add :message, :text, null: false                    # "Сантехник, 60,000 сум, 500м"
      add :notification_type, :string, null: false        # "job_nearby", "event_nearby"

      # Метаданные
      add :distance_meters, :integer                      # Расстояние до поста
      add :priority, :string, default: "normal"           # "low", "normal", "high", "urgent"

      # Статус
      add :status, :string, default: "sent"               # "sent", "read", "clicked"
      add :read_at, :naive_datetime                       # Когда прочитали
      add :clicked_at, :naive_datetime                    # Когда кликнули

      # Доставка
      add :delivery_method, :string, default: "websocket" # "websocket", "email", "sms"
      add :delivered_at, :naive_datetime                  # Когда доставили

      timestamps()
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:post_id])
    create index(:notifications, [:status])
    create index(:notifications, [:notification_type])
    create index(:notifications, [:user_id, :status])
    create index(:notifications, [:inserted_at])
  end
end
