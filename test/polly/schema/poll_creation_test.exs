defmodule Polly.TestPollCreation do
  alias Polly.ETSStorage
  alias Polly.Schema.Poll
  import ExUnit.Callbacks

  setup do
    :ets.delete_all_objects(:polls)
    :ets.delete_all_objects(:polls_votes)
    :ets.delete_all_objects(:polls_options_votes)
    :ets.delete_all_objects(:user_tokens)
    :ok
  end

  def create_and_check_poll(poll_params) do
    poll = %Poll{
      id: Ecto.UUID.generate(),
      title: poll_params[:title],
      description: poll_params[:description],
      options: poll_params[:options],
      total_votes: 0,
      creator_username: poll_params[:creator_username],
      created_at: DateTime.utc_now()
    }

    case ETSStorage.add_poll(poll) do
      :ok ->
        if ETSStorage.poll_exists?(poll.id) do
          IO.puts("Poll with ID #{poll.id} exists in ETS.")
        else
          IO.puts("Poll with ID #{poll.id} does not exist in ETS.")
        end

      {:error, reason} ->
        IO.puts("Failed to add poll: #{reason}")
    end
  end

  def check_all_polls do
    ETSStorage.list_all_polls()
    |> Enum.each(fn {id, poll} ->
      IO.inspect({id, poll}, label: "Poll")
    end)
  end

end
