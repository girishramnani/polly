defmodule Polly.Schema.Vote do
  @moduledoc """
  Represents a vote cased by a user towards a poll
  """
  use Ecto.Schema

  @type t :: %__MODULE__{}

  embedded_schema do
    field(:username, :string)
    field(:poll_id, :string)
    field(:option_id, :string)
  end
end
