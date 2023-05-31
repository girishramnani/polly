defmodule PollyWeb.LoginLiveTest do
  use PollyWeb.ConnCase

  import Phoenix.LiveViewTest

  @test_username "other_testusername"

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/username/log_in")

      assert html =~ "Sign in"
    end

    test "login using the page and confirm that VoteManager starts", %{conn: conn} do
      {:ok, login_live, _html} = live(conn, ~p"/username/log_in")
      form = login_live |> form("#login-form", username: @test_username)

      submit_form(form, conn)
      # we check that there is a pid that exists in the voteRegistry for this user
      assert Registry.lookup(Polly.VoteRegistry, @test_username) |> length() == 1
    end
  end
end
