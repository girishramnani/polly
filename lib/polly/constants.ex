defmodule Polly.Constants do
  @moduledoc """
  This module holds all the constants used across the system
  """

  @constants [
    polls_topic: "polls",
    new_vote_event: "new_vote",
    new_poll_event: "new_poll"
  ]

  Enum.map(@constants, fn {key, value} ->
    def encode(unquote(key)), do: unquote(value)
  end)
end
