defmodule PollyWeb.UserSessionController do
  use PollyWeb, :controller

  alias PollyWeb.UserAuth

  def create(conn, %{"username" => username} = user_params) do
    conn
    |> put_flash(:info, "Welcome back!")
    |> UserAuth.log_in_user(user_params)
    |> start_vote_manager(username)
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp start_vote_manager(conn, username) do
    # just a quick way to check the user did actually get a session assigned
    if get_session(conn, :user_token) !== nil do
      Polly.VoteSupervisor.start_child(username)
    end

    conn
  end
end
