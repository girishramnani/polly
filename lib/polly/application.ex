defmodule Polly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      {Registry, keys: :unique, name: Polly.VoteRegistry, partitions: System.schedulers_online()},
      {PartitionSupervisor, child_spec: DynamicSupervisor, name: Polly.DynamicSupervisors},
      PollyWeb.Telemetry,
      {Phoenix.PubSub, name: Polly.PubSub},
      {Finch, name: Polly.Finch},
      PollyWeb.Endpoint
      # Start a worker by calling: Polly.Worker.start_link(arg)
      # {Polly.Worker, arg}
    ]

    ## Do one off inits here

    # Create all the ets tables related to polls here
    Polly.PollsManager.init()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Polly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PollyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
