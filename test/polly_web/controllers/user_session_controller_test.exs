defmodule PollyWeb.UserSessionControllerTest do
  use PollyWeb.ConnCase, async: true

  @test_username "username"

  setup do
    {:ok, user: %{"username" => @test_username}}
  end

  describe "POST /username/log_in" do
    test "logs the user in", %{conn: conn} do
      conn =
        post(conn, ~p"/username/log_in", %{
          "username" => @test_username
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ @test_username
    end
  end

  describe "DELETE /username/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/username/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/username/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
