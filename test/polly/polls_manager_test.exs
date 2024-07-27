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

  describe "list_polls_with_ids/0" do
    setup [:create_poll]

    test "lists all polls with ids", %{poll: poll} do
      assert PollsManager.add_poll(poll) == :ok
      polls = PollsManager.list_polls_with_ids()
      assert length(polls) == 1
      assert Enum.any?(polls, fn {id, _} -> id == poll.id end)
    end
  end

  describe "get_poll!/1" do
    setup [:create_poll]

    test "retrieves a poll by id", %{poll: poll} do
      assert PollsManager.add_poll(poll) == :ok
      retrieved_poll = PollsManager.get_poll!(poll.id)
      assert retrieved_poll == poll
    end
  end

  describe "get_poll_simple!/1" do
    setup [:create_poll]

    test "retrieves a poll by id without option votes", %{poll: poll} do
      assert PollsManager.add_poll(poll) == :ok
      retrieved_poll = PollsManager.get_poll_simple!(poll.id)
      assert retrieved_poll == poll
    end
  end

  describe "has_option?/2" do
    setup [:create_poll]

    test "returns true if poll has the option", %{poll: poll} do
      assert PollsManager.add_poll(poll) == :ok
      option = hd(poll.options)
      assert PollsManager.has_option?(poll.id, option.id) == true
    end

    test "returns false if poll does not have the option", %{poll: poll} do
      assert PollsManager.add_poll(poll) == :ok
      assert PollsManager.has_option?(poll.id, "non-existent-option-id") == false
    end
  end

  describe "update_poll/2" do
    setup [:create_poll]

    test "updates an existing poll", %{poll: poll} do
      assert PollsManager.add_poll(poll) == :ok
      updated_poll = %Poll{poll | title: "Updated Title"}
      assert PollsManager.update_poll(poll.id, updated_poll) == :ok
      assert PollsManager.get_poll!(poll.id).title == "Updated Title"
    end

    test "returns error if poll does not exist" do
      updated_poll = %Poll{id: "non-existent-id", title: "Updated Title"}
      assert {:error, :poll_not_found} = PollsManager.update_poll("non-existent-id", updated_poll)
    end
  end

  describe "change_poll/2" do
    setup [:create_poll]

    test "returns a changeset for an existing poll", %{poll: poll} do
      changeset = PollsManager.change_poll(poll, %{"title" => "Changed Title"})
      assert changeset.valid?
      assert changeset.changes.title == "Changed Title"
    end

    test "returns an invalid changeset with errors" do
      changeset = PollsManager.change_poll(%Poll{}, %{"title" => nil})
      assert changeset.valid? == false
      assert changeset.errors[:title] != nil
    end
  end

end
