defmodule AirQualityServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "1234")

    topologies = [
      example: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    # List all child processes to be supervised
    children = [
      {Cluster.Supervisor, [topologies, [name: AirQualityServer.ClusterSupervisor]]},
      {AirQualityDataStore, name: AirQualityDataStore.Worker},
      {Task.Supervisor, name: AirQualityServer.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> AirQualityServer.accept(port) end}, restart: :permanent)
      # Starts a worker by calling: AirQualityServer.Worker.start_link(arg)
      # {AirQualityServer.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AirQualityServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
