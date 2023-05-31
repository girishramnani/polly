defmodule Polly.PollsManagerTest do
  use ExUnit.Case

  import Polly.Factory
  alias Polly.PollsManager
  alias Polly.Schema.Poll

  defp create_poll(_) do
    {:ok, poll} =
      Poll.changeset(%Poll{}, build(:poll, %{})) |> Ecto.Changeset.apply_action(:update)

    %{poll: poll}
  end

  describe "add_poll/1" do
    setup [:create_poll]

    test "setting a poll with nil id to confirm it fails" do
      assert {:error, :nil_poll_id} = PollsManager.add_poll(%Poll{title: "Something"})
    end

    test "confirm that setting a correct poll gets correctly stored", %{poll: poll} do
      assert PollsManager.add_poll(poll) == :ok
      assert PollsManager.get_poll!(poll.id) == poll
    end
  end

  describe "incr_vote!/2" do
    setup [:create_poll]

    test "throws error if non existent option_id is provided", %{poll: poll} do
      assert PollsManager.add_poll(poll) == :ok

      assert PollsManager.incr_vote!(poll.id, "non-existent-option-id") ==
               {:error, :bad_option_id}
    end

    test "correctly increments the option_id", %{poll: poll} do
      assert PollsManager.add_poll(poll) == :ok
      option = hd(poll.options)
      assert PollsManager.incr_vote!(poll.id, option.id) == :ok

      poll = PollsManager.get_poll!(poll.id, true)
      assert Enum.find(poll.options, nil, fn p_option -> p_option.id == option.id end).votes == 1
    end
  end
end
