defmodule Polly.PollsManager do
  alias Polly.Schema.Poll
  # alias Polly.StorageBehaviour

  @storage_module Application.compile_env(:polly, :storage_module, Polly.ETSStorage)

  def init() do
    @storage_module.init()
  end

  @spec add_poll(Poll.t()) :: :ok | {:error, :nil_poll_id}
  def add_poll(%Poll{} = poll) do
    @storage_module.add_poll(poll)
  end

  @spec incr_vote!(binary(), binary()) :: :ok | {:error, atom()}
  def incr_vote!(poll_id, option_id) when is_binary(poll_id) and is_binary(option_id) do
    if has_option?(poll_id, option_id) do
      @storage_module.incr_vote!(poll_id, option_id)
    else
      {:error, :bad_option_id}
    end
  end

  @spec list_polls_with_ids :: Keyword.t()
  def list_polls_with_ids() do
    @storage_module.list_polls_with_ids()
    |> Enum.map(fn {id, poll} ->
      {id, Map.replace(poll, :total_votes, get_poll_votes!(poll.id))}
    end)
  end

  @spec get_poll!(binary(), boolean()) :: Poll.t()
  def get_poll!(poll_id, with_option_votes \\ false) do
    case @storage_module.get_poll!(poll_id, with_option_votes) do
      nil -> raise ArgumentError, message: "Poll with ID #{poll_id} not found"
      poll -> Map.replace(poll, :total_votes, get_poll_votes!(poll_id))
              |> replace_option_votes(with_option_votes)
    end
  end

  @spec get_poll_simple!(binary()) :: Poll.t()
  def get_poll_simple!(id) do
    @storage_module.get_poll!(id, false)
  end

  defp get_poll_votes!(poll_id) do
    @storage_module.get_poll_votes!(poll_id)
  end

  defp replace_option_votes(poll, true) do
    updated_options =
      Enum.map(poll.options, fn option ->
        Map.replace(option, :votes, safe_lookup_element(option.id))
      end)

    Map.replace(poll, :options, updated_options)
  end

  defp replace_option_votes(poll, false) do
    poll
  end

  def has_option?(poll_id, option_id) do
    poll_id
    |> @storage_module.get_poll!(false)
    |> Map.fetch!(:options)
    |> Enum.any?(fn option ->
      option.id == option_id
    end)
  end

  defp safe_lookup_element(option_id) do
    @storage_module.safe_lookup_element(option_id)
  end

  @spec update_poll(binary(), Poll.t()) :: :ok | {:error, atom()}
def update_poll(poll_id, %Poll{} = updated_poll) do
  if @storage_module.get_poll!(poll_id) do
    @storage_module.update_poll(poll_id, updated_poll)
  else
    {:error, :poll_not_found}
  end
end

  @spec change_poll(Poll.t(), map()) :: Ecto.Changeset.t()
  def change_poll(%Poll{} = poll, attrs \\ %{}) do
    Poll.changeset(poll, attrs)
  end
end
