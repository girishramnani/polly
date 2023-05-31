defmodule Polly.Polls do
  @moduledoc """
  This module holds functions related to CRUD operations for Polls
  """
  alias Polly.Schema.Poll

  def list_polls() do
    Polly.PollsManager.list_polls_with_ids()
  end

  @spec get_poll(binary(), boolean()) :: Poll.t() | nil
  def get_poll(poll_id, with_option_votes \\ false) do
    try do
      Polly.PollsManager.get_poll!(poll_id, with_option_votes)
    rescue
      ArgumentError ->
        nil
    end
  end

  @spec create_poll(map()) :: {:ok, Poll.t()} | {:error, Ecto.Changeset.t()}
  def create_poll(params) do
    Poll.changeset(%Poll{}, params)
    |> Ecto.Changeset.apply_action(:update)
    |> do_create_poll()
  end

  defp do_create_poll({:ok, %Poll{} = poll}) do
    :ok = Polly.PollsManager.add_poll(poll)
    {:ok, poll}
  end

  defp do_create_poll({:error, changeset}) do
    {:error, changeset}
  end
end
