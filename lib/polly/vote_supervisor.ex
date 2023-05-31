defmodule Polly.VoteSupervisor do
  @moduledoc """
  VoteSupervisor is a dynamic supervisor which is responsible for managing all the VoteManagers.
  We are using a Registry to keep track of all VoteManagers created.
  The reason for using the Registry is that this supervisor could potentially be created under a PartitionedSupervisor
  and to fetch/find a VoteManager would become a complicated task without a Registry.
  """
  use DynamicSupervisor

  require Logger

  @registry_name Polly.VoteRegistry

  def start_link(_) do
    DynamicSupervisor.start_link(
      __MODULE__,
      [
        strategy: :one_for_one,
        max_restarts: 10
      ],
      name: __MODULE__
    )
  end

  @doc """
  Starts a VoteManager process under the Dynamic supervisor.
  It also checks if a VoteManager for the same username already exists or not,
  if it does then nothing is done and :ignore is returned
  """
  @spec start_child(binary()) :: DynamicSupervisor.on_start_child()
  def start_child(username) do
    case get_pid(username) do
      nil ->
        child = {Polly.VoteManager, username: username}

        Logger.info("#{__MODULE__} - Starting VoteManager for Username: #{username}")

        DynamicSupervisor.start_child(
          {:via, PartitionSupervisor, {Polly.DynamicSupervisors, self()}},
          child
        )

      _pid ->
        :ignore
    end
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(init_arg)
  end

  @spec get_pid(String.t()) :: pid() | nil
  defp get_pid(username) do
    case Registry.lookup(@registry_name, username) do
      [{pid, nil}] ->
        pid

      [] ->
        nil
    end
  end
end
