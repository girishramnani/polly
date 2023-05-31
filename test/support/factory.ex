defmodule Polly.Factory do
  @moduledoc """
  Provides factory methods for creating mock Poll and Option data for tests
  """
  use ExMachina

  def poll_factory do
    %{
      title: sequence(:title, &"Post title (Part #{&1})"),
      description: "Test description",
      creator_username: "username",
      options: build_list(4, :option)
    }
  end

  def option_factory do
    %{
      text: sequence(:text, &"Option #{&1}")
    }
  end
end
