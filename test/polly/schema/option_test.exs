defmodule Polly.Schema.OptionTest do
  use ExUnit.Case

  alias Polly.Schema.Option

  describe "changeset/2" do
    test "fails when blank attribute map is provide" do
      changeset = Option.changeset(%Option{}, %{})
      assert changeset.valid? == false
    end

    test "passes and generates the id as expected" do
      changeset = Option.changeset(%Option{}, %{"text" => "Something"})

      assert changeset.valid?
      assert Map.has_key?(changeset.changes, :id)
    end
  end
end
