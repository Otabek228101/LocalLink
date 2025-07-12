defmodule LocallinkApi.Repo.Migrations.EnablePostgis do
  use Ecto.Migration

  @disable_ddl_transaction true
  def up do
    IO.puts("✅ Проверяем наличие PostGIS расширений...")

    result =
      Ecto.Adapters.SQL.query!(
        LocallinkApi.Repo,
        """
        SELECT extname
        FROM pg_extension
        WHERE extname IN ('postgis', 'postgis_topology')
        """,
        []
      )

    case result.rows do
      [] ->
        raise """
        PostGIS extensions not found in the database!
        Убедитесь, что init.sql был смонтирован и выполнен при стартe контейнера.
        """

      found ->
        IO.puts("✅ Расширения найдены: #{Enum.join(List.flatten(found), ", ")}")
    end
  end

  def down do
    execute "DROP EXTENSION IF EXISTS postgis_topology CASCADE"
    execute "DROP EXTENSION IF EXISTS postgis CASCADE"
  end
end
