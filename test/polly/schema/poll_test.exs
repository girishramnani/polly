defmodule Polly.Schema.PollTest do
  use ExUnit.Case

  alias Polly.Schema.Poll

  describe "changeset/2" do
    test "fails when blank attribute map is provide" do
      changeset = Poll.changeset(%Poll{}, %{})
      assert changeset.valid? == false
    end

    test "passes and generates the id as expected" do
      changeset = Poll.changeset(%Poll{}, %{"title" => "Something"})

      assert changeset.valid?
      assert Map.has_key?(changeset.changes, :id)
      assert Map.has_key?(changeset.changes, :created_at)
    end
  end
end
