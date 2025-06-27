defmodule LocallinkApi.Repo do
  use Ecto.Repo,
    otp_app: :locallink_api,
    adapter: Ecto.Adapters.Postgres
end
