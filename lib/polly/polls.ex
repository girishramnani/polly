defmodule Polly.Polls do
  @moduledoc """
  This module holds functions related to CRUD operations for Polls
  """
  alias Polly.Schema.Poll

  @spec list_polls() :: [Poll.t()]
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

  @spec get_poll!(binary()) :: Poll.t()
  def get_poll!(id) do
    Polly.PollsManager.get_poll_simple!(id)
  end

  @spec create_poll(map()) :: {:ok, Poll.t()} | {:error, Ecto.Changeset.t()}
  def create_poll(params) do
    Poll.changeset(%Poll{}, params)
    |> Ecto.Changeset.apply_action(:insert)
    |> do_create_poll()
  end

  defp do_create_poll({:ok, %Poll{} = poll}) do
    :ok = Polly.PollsManager.add_poll(poll)
    {:ok, poll}
  end

  defp do_create_poll({:error, changeset}) do
    {:error, changeset}
  end

  @spec update_poll(Poll.t(), map()) :: {:ok, Poll.t()} | {:error, Ecto.Changeset.t()}
  def update_poll(%Poll{} = poll, attrs) do
    poll
    |> Poll.changeset(attrs)
    |> Ecto.Changeset.apply_action(:update)
    |> do_update_poll(poll)
  end

  defp do_update_poll({:ok, %Poll{} = updated_poll}, poll_id) do
    :ok = Polly.PollsManager.update_poll(poll_id, updated_poll)
    {:ok, updated_poll}
  end


  defp do_update_poll({:error, changeset}, _poll) do
    {:error, changeset}
  end

  @spec change_poll(Poll.t(), map()) :: Ecto.Changeset.t()
  def change_poll(%Poll{} = poll, attrs \\ %{}) do
    Poll.changeset(poll, attrs)
  end
end
