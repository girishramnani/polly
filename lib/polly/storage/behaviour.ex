defmodule Polly.StorageBehaviour do
  alias Polly.Schema.Poll

  @callback init() :: :ok
  @callback add_poll(Poll.t()) :: :ok | {:error, :nil_poll_id}
  @callback incr_vote!(binary(), binary()) :: :ok | {:error, atom()}
  @callback list_polls_with_ids() :: Keyword.t()
  @callback get_poll!(binary(), boolean()) :: Poll.t()
  @callback get_poll_votes!(binary()) :: integer()
  @callback has_option?(binary(), binary()) :: boolean()
  @callback safe_lookup_element(binary()) :: integer()
  @callback update_poll(binary(), Poll.t()) :: :ok | {:error, atom()}
  # @callback replace_option_votes(Poll.t(), boolean()) :: Poll.t()

end
