defmodule LocallinkApi.Repo.Migrations.CreateOffers do
  use Ecto.Migration

  def change do
    create table(:offers, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Цены
      add :original_price, :decimal, precision: 10, scale: 2    # Цена из поста
      add :offered_price, :decimal, precision: 10, scale: 2    # Предложенная цена
      add :currency, :string, default: "UZS"

      # Сообщение от исполнителя
      add :message, :text                                      # "Могу сделать дешевле, опыт 5 лет"

      # Статус предложения
      add :status, :string, default: "pending"                # pending, accepted, declined, completed

      # Временные рамки
      add :expires_at, :naive_datetime                         # Когда истекает предложение
      add :estimated_completion, :naive_datetime               # Когда планирует завершить

      # Связи
      add :post_id, references(:posts, type: :binary_id), null: false
      add :offerer_id, references(:users, type: :binary_id), null: false    # Кто предлагает
      add :receiver_id, references(:users, type: :binary_id), null: false   # Кому предлагают
      add :conversation_id, references(:conversations, type: :binary_id)    # Связанный чат

      # Метаданные
      add :accepted_at, :naive_datetime                        # Когда приняли
      add :completed_at, :naive_datetime                       # Когда завершили работу
      add :work_started_at, :naive_datetime                    # Когда начали работу

      timestamps()
    end

    # Индексы
    create index(:offers, [:post_id])
    create index(:offers, [:offerer_id])
    create index(:offers, [:receiver_id])
    create index(:offers, [:status])
    create index(:offers, [:conversation_id])

    # Композитные индексы
    create index(:offers, [:post_id, :status])
    create index(:offers, [:receiver_id, :status])
    create index(:offers, [:offerer_id, :status])

    # Ограничение: один пользователь может сделать только одно предложение на пост
    create unique_index(:offers, [:post_id, :offerer_id])
  end
end
