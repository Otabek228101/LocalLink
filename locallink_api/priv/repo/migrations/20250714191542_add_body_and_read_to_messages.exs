defmodule LocallinkApi.Repo.Migrations.AddBodyAndReadToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      # Добавляем колонки только если их ещё нет
      add_if_not_exists :body, :text, null: false
      add_if_not_exists :read, :boolean, default: false, null: false
    end
  end
end
