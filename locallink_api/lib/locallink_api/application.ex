defmodule LocallinkApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LocallinkApiWeb.Telemetry,
      LocallinkApi.Repo,
      {DNSCluster, query: Application.get_env(:locallink_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LocallinkApi.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LocallinkApi.Finch},
      # Start a worker by calling: LocallinkApi.Worker.start_link(arg)
      # {LocallinkApi.Worker, arg},
      # Start to serve requests, typically the last entry
      LocallinkApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LocallinkApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LocallinkApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
