defmodule Polly.PollsManager do
  @moduledoc """
  PollsManager takes care of all the state related to Polls.
  Essentially PollsManager stores data using 3 read and write concurrency enabled ets table.
  They are as

  * `:polls` - Stores all the Poll structs with their options, :id of the poll is used as a key
    for fast lookup

  * `:polls_votes` - Stores the total votes submitted towards a Poll. This table contains the vote
  counts in the format of {:id, count}. update_counter method provided by :ets is used to atomically
  increment these votes

  * `:polls_options_votes` - Stores the votes per Option of a Poll. Each Poll can have many options
  and for each option vote count is stored in form of {:option_id, count}. Here as :id of an option
  is a unique uuid and hence an option can be uniquely identified without knowing the :if of the poll
  """
  alias Polly.Schema.Poll

  @polls :polls
  @polls_votes :polls_votes
  @polls_options_votes :polls_options_votes

  @doc """
  Creates all the ets tables needed for functioning of the polls manager
  """
  def init() do
    :ets.new(@polls, [:public, :named_table, write_concurrency: true, read_concurrency: true])

    :ets.new(@polls_votes, [
      :public,
      :named_table,
      write_concurrency: true,
      read_concurrency: true
    ])

    :ets.new(@polls_options_votes, [
      :public,
      :named_table,
      write_concurrency: true,
      read_concurrency: true
    ])

    :ok
  end

  @doc """
  Inserts the poll in the @polls ets table with id as the key. Also adds an entry in the @polls_votes table
  for total votes as 0.
  """
  @spec add_poll(Poll.t()) :: :ok | {:error, :nil_poll_id}
  def add_poll(%Poll{} = poll) do
    if poll.id do
      :ets.insert_new(@polls, {poll.id, poll})
      :ets.insert_new(@polls_votes, {poll.id, 0})
      :ok
    else
      {:error, :nil_poll_id}
    end
  end

  @doc """
  Increments the total vote counter for the poll and the option vote counter which is
  ment to keep track of votes per option. This operation is not atomic in nature
  but still can be called parallely as there are only two operations being performed here
  they both are independent, non-failing and atomic.
  """
  @spec incr_vote!(binary(), binary()) :: :ok | {:error, atom()}
  def incr_vote!(poll_id, option_id) when is_binary(poll_id) and is_binary(option_id) do
    if has_option?(poll_id, option_id) do
      :ets.update_counter(@polls_votes, poll_id, {2, 1})
      :ets.update_counter(@polls_options_votes, option_id, {2, 1}, {option_id, 0})
      :ok
    else
      {:error, :bad_option_id}
    end
  end

  @doc """
  Lists all the polls from the underlying ets table
  """
  @spec list_polls_with_ids :: Keyword.t()
  def list_polls_with_ids() do
    :ets.tab2list(@polls)
    |> Enum.map(fn {id, poll} ->
      {id, Map.replace(poll, :total_votes, get_poll_votes!(poll.id))}
    end)
  end

  @spec get_poll!(binary(), boolean()) :: Poll.t()
  def get_poll!(poll_id, with_option_votes \\ false) do
    # here 2 means second item of the tuple i.e. the Poll itself.
    :ets.lookup_element(@polls, poll_id, 2)
    |> Map.replace(:total_votes, get_poll_votes!(poll_id))
    |> replace_option_votes(with_option_votes)
  end

  defp get_poll_votes!(poll_id) do
    :ets.lookup_element(@polls_votes, poll_id, 2)
  end

  defp replace_option_votes(poll, true) do
    # here we go over the options and set the current votes
    updated_options =
      Enum.map(poll.options, fn option ->
        Map.replace(option, :votes, safe_lookup_element(option.id))
      end)

    Map.replace(poll, :options, updated_options)
  end

  # here the second argument is 'with_option_votes' which when set to false, the poll
  # is returned as is.
  defp replace_option_votes(poll, false) do
    poll
  end

  defp has_option?(poll_id, option_id) do
    poll_id
    |> get_poll!(false)
    |> Map.fetch!(:options)
    |> Enum.any?(fn option ->
      option.id == option_id
    end)
  end

  defp safe_lookup_element(option_id) do
    try do
      :ets.lookup_element(@polls_options_votes, option_id, 2)
    rescue
      ArgumentError ->
        0
    end
  end
end
