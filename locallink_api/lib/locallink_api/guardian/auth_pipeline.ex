defmodule LocallinkApi.Guardian.AuthPipeline do
  import Plug.Conn
  import Guardian.Plug

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> Guardian.Plug.VerifyHeader.call(scheme: "Bearer")
    |> Guardian.Plug.EnsureAuthenticated.call([])
    |> Guardian.Plug.LoadResource.call([])
  end
end
