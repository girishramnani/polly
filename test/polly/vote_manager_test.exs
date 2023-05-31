defmodule Polly.VoteManagerTest do
  use ExUnit.Case

  import Polly.Factory
  alias Polly.VoteManager
  alias Polly.Schema.Poll

  @test_username "username"

  defp create_poll(_) do
    {:ok, poll} =
      Poll.changeset(%Poll{}, build(:poll, %{})) |> Ecto.Changeset.apply_action(:update)

    %{poll: poll}
  end

  describe "add_vote/3" do
    setup [:create_poll]

    test "calling multiple times still should yield one vote", %{poll: poll} do
      VoteManager.start_link(username: @test_username)
      option = hd(poll.options)
      assert VoteManager.add_vote(@test_username, poll.id, option.id) == :ok
      assert VoteManager.add_vote(@test_username, poll.id, option.id) == :ok

      assert VoteManager.fetch_vote(@test_username, poll.id) == {true, option.id}
    end
  end
end
