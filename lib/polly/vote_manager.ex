defmodule Polly.VoteManager do
  @moduledoc """
  VoteManager is a gen-server responsible for holding and managing votes for a user.
  A VoteManager process holds votes casted by a single user. Each instance is registered
  to the VoteRegistry for fast and convinient discovery and is created under a DynamicSupervisor.

  This process design works well here because the act of "storing a vote" and checking if a user
  has "already cast a vote" are independent operation on a user level.

  The state of the gen server is of the format map(poll_id => %Vote{}). This has been done to provide
  O(1) lookups.
  """
  use GenServer

  require Logger

  alias Polly.Schema.Vote

  @registry Polly.VoteRegistry

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  def start_link(init_arg) do
    {:ok, username} = Keyword.fetch(init_arg, :username)
    GenServer.start_link(__MODULE__, username, name: via(username))
  end

  @doc """
  adds a vote for the user with username for a poll identified by a poll id. The
  option which the vote if for is identified by option_id.
  This operation is idempotent in nature and hence running it multiple times would
  yield the same outcome as running it once.
  """
  @spec add_vote(binary(), binary(), binary()) :: :ok
  def add_vote(username, poll_id, option_id)
      when is_binary(username) and is_binary(poll_id) and is_binary(option_id) do
    Logger.info(
      "#{__MODULE__} - Adding a vote for username: #{username}, poll_id: #{poll_id}, option_id: #{option_id}"
    )

    username |> via() |> GenServer.call({:add_vote, username, poll_id, option_id})
  end

  @doc """
  Fetches the option id for the user if they have casted a vote for a poll.
  The poll is identified using the poll id.
  A tuple is returned with first value as true or false based on if the user
  has voted in the poll and second value is the option id which will be nil
  if the user hasn't voted.
  """
  @spec fetch_vote(binary(), binary()) :: {boolean(), binary() | nil}
  def fetch_vote(username, poll_id) do
    username |> via() |> GenServer.call({:fetch_vote, poll_id})
  end

  @impl true
  def handle_call({:fetch_vote, poll_id}, _from, state) do
    response =
      case Map.fetch(state, poll_id) do
        :error ->
          {false, nil}

        {:ok, vote} ->
          {true, vote.option_id}
      end

    {:reply, response, state}
  end

  @doc """
  Adds the vote to the state of the gen server. The poll is stored in the state
  in the form of map(poll_id => %Vote{}). This is done to provide O(1) lookup.
  """
  @impl true
  def handle_call({:add_vote, username, poll_id, option_id}, _from, state) do
    {:reply, :ok,
     Map.put_new(state, poll_id, %Vote{
       poll_id: poll_id,
       option_id: option_id,
       username: username
     })}
  end

  defp via(username) do
    {:via, Registry, {@registry, username}}
  end
end
