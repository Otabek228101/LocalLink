# точка входа main , включаеи всё что нужно

defmodule LocallinkApi.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      LocallinkApi.Repo,
      {Phoenix.PubSub, name: LocallinkApi.PubSub},
      LocallinkApiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: LocallinkApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    LocallinkApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
