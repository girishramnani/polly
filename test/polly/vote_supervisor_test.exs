defmodule Polly.VoteSupervisorTest do
  use ExUnit.Case

  @test_username "new_username"

  describe "start_child/1" do
    test "starts a VoteManager correctly and doesn't allow multiple instances with same username" do
      {:ok, new_pid} = Polly.VoteSupervisor.start_child(@test_username)
      assert Polly.VoteSupervisor.start_child(@test_username) == :ignore
      [{pid, nil}] = Registry.lookup(Polly.VoteRegistry, @test_username)
      assert pid == new_pid
    end
  end
end
