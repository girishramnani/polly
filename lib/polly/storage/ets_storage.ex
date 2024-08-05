defmodule Polly.ETSStorage do
  @behaviour Polly.StorageBehaviour
  alias Polly.Schema.Poll

  @polls :polls
  @polls_votes :polls_votes
  @polls_options_votes :polls_options_votes

  @impl Polly.StorageBehaviour
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

  @impl Polly.StorageBehaviour
  def add_poll(%Poll{} = poll) do
    if poll.id do
      :ets.insert_new(@polls, {poll.id, poll})
      :ets.insert_new(@polls_votes, {poll.id, 0})
      :ok
    else
      {:error, :nil_poll_id}
    end
  end

  @impl Polly.StorageBehaviour
  def incr_vote!(poll_id, option_id) when is_binary(poll_id) and is_binary(option_id) do
    if has_option?(poll_id, option_id) do
      :ets.update_counter(@polls_votes, poll_id, {2, 1})
      :ets.update_counter(@polls_options_votes, option_id, {2, 1}, {option_id, 0})
      :ok
    else
      {:error, :bad_option_id}
    end
  end

  @impl Polly.StorageBehaviour
  def list_polls_with_ids() do
    :ets.tab2list(@polls)
    |> Enum.map(fn {id, poll} ->
      {id, Map.replace(poll, :total_votes, get_poll_votes!(id))}
    end)
  end

  @impl Polly.StorageBehaviour
  def get_poll!(poll_id, with_option_votes \\ false) do
    :ets.lookup_element(@polls, poll_id, 2)
    |> Map.replace(:total_votes, get_poll_votes!(poll_id))
    |> replace_option_votes(with_option_votes)
  end

  @impl Polly.StorageBehaviour
  def get_poll_votes!(poll_id) do
    :ets.lookup_element(@polls_votes, poll_id, 2)
  end

  def replace_option_votes(poll, true) do
    updated_options =
      Enum.map(poll.options, fn option ->
        Map.replace(option, :votes, safe_lookup_element(option.id))
      end)

    Map.replace(poll, :options, updated_options)
  end

  def replace_option_votes(poll, false), do: poll

  @impl Polly.StorageBehaviour
  def has_option?(poll_id, option_id) do
    poll_id
    |> get_poll!(false)
    |> Map.fetch!(:options)
    |> Enum.any?(fn option -> option.id == option_id end)
  end

  @impl Polly.StorageBehaviour
  def safe_lookup_element(option_id) do
    try do
      :ets.lookup_element(@polls_options_votes, option_id, 2)
    rescue
      ArgumentError -> 0
    end
  end

  @impl Polly.StorageBehaviour
  @spec update_poll(binary(), Poll.t()) :: :ok | {:error, atom()}
  def update_poll(poll_id, %Poll{} = updated_poll) do
    if :ets.lookup(@polls, poll_id) != [] do
      :ets.insert(@polls, {poll_id, updated_poll})
      :ok
    else
      {:error, :poll_not_found}
    end
  end
end
