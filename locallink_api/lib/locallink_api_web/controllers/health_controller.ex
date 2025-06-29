defmodule LocallinkApiWeb.HealthController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Repo

  def check(conn, _params) do
    db_status = 
      try do
        Ecto.Adapters.SQL.query!(Repo, "SELECT 1", [])
        "ok"
      rescue
        _ -> "error"
      end

    health_data = %{
      status: (if db_status == "ok", do: "healthy", else: "unhealthy"),
      timestamp: DateTime.utc_now(),
      version: "1.0.0",
      database: db_status
    }

    status_code = if health_data.status == "healthy", do: 200, else: 503

    conn
    |> put_status(status_code)
    |> json(health_data)
  end
end
