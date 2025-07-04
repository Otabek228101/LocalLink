defmodule LocallinkApi.Repo.Migrations.CreateNotificationPreferences do
  use Ecto.Migration

  def change do
    create table(:notification_preferences, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Пользователь
      add :user_id, references(:users, type: :binary_id), null: false

      # Настройки геолокации
      add :current_location, :geometry                    # Текущее местоположение
      add :home_location, :geometry                       # Домашний адрес
      add :work_location, :geometry                       # Рабочий адрес
      add :notification_radius_km, :float, default: 2.0   # Радиус уведомлений (км)

      # Типы уведомлений
      add :notify_jobs, :boolean, default: true           # Уведомления о работе
      add :notify_tasks, :boolean, default: true          # Уведомления о задачах
      add :notify_events, :boolean, default: true         # Уведомления о событиях
      add :notify_help, :boolean, default: true           # Уведомления о помощи

      # Временные рамки
      add :quiet_hours_start, :time                       # Начало тихих часов (22:00)
      add :quiet_hours_end, :time                         # Конец тихих часов (08:00)
      add :weekend_notifications, :boolean, default: true # Уведомления на выходных

      # Фильтры
      add :min_price, :decimal, precision: 10, scale: 2   # Минимальная цена для уведомлений
      add :max_price, :decimal, precision: 10, scale: 2   # Максимальная цена
      add :skills_filter, {:array, :string}, default: []  # Уведомления только по навыкам

      # Статус
      add :is_active, :boolean, default: true             # Включены ли уведомления
      add :last_location_update, :naive_datetime          # Когда обновлялась геолокация

      timestamps()
    end

    create unique_index(:notification_preferences, [:user_id])
    create index(:notification_preferences, [:is_active])

    # Пространственные индексы для быстрого поиска
    execute "CREATE INDEX notification_current_location_idx ON notification_preferences USING GIST (current_location)"
    execute "CREATE INDEX notification_home_location_idx ON notification_preferences USING GIST (home_location)"
  end
end
