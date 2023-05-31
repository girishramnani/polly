defmodule PollyWeb.PollLiveTest do
  use PollyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Polly.Factory

  alias Polly.VoteManager
  alias Polly.Polls
  alias Polly.PollsManager

  @invalid_attrs %{}

  @test_username "username"

  setup do
    {:ok, user: %{"username" => @test_username}}
  end

  defp create_poll(_) do
    {:ok, poll} = Polls.create_poll(build(:poll, %{}))

    %{poll: poll}
  end

  describe "Index" do
    setup [:create_poll]

    test "lists all polls", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Listing Polls"
    end

    test "check redirect works", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, index_live, _html} = live(conn, ~p"/")

      index_live |> element("a", "New Poll") |> render_click()

      assert_redirect(index_live, ~p"/polls/new")
    end

    test "create a poll fails for unauthenticated user", %{conn: conn, user: user} do
      assert {:error,
              {:redirect,
               %{
                 flash: %{"error" => "You must log in to access this page."},
                 to: "/username/log_in"
               }}} ==
               live(conn, ~p"/polls/new")

      conn = log_in_user(conn, user)
      {:ok, _index_live, _html} = live(conn, ~p"/polls/new")
    end

    test "create a poll", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, index_live, _html} = live(conn, ~p"/polls/new")

      assert index_live
             |> form("#poll-form", poll: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#poll-form",
               poll: %{
                 description: "Test description",
                 title: "Post title (Part 3)"
               }
             )
             |> render_submit(%{
               poll: %{
                 options: [
                   %{text: "Option 12"},
                   %{text: "Option 13"},
                   %{text: "Option 14"},
                   %{text: "Option 15"}
                 ]
               }
             })

      assert_patch(index_live, ~p"/")
      html = render(index_live)

      assert html =~ "Poll created successfully"
    end
  end

  describe "Show" do
    setup [:create_poll]

    test "displays poll", %{conn: conn, poll: poll, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _show_live, html} = live(conn, ~p"/polls/#{poll}")

      assert html =~ "Show Poll"
    end

    test "redirect to home when trying to go to a non-existent poll", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      assert {:error,
              {:live_redirect,
               %{flash: %{"error" => "Poll with the provided id doesn't exist"}, to: "/"}}} ==
               live(conn, ~p"/polls/non_existent_id")
    end

    test "vote for a poll and confirm you cannot vote again", %{
      conn: conn,
      poll: poll,
      user: user
    } do
      conn = log_in_user(conn, user)
      {:ok, show_live, html} = live(conn, ~p"/polls/#{poll}")
      assert html =~ "Show Poll"
      option = hd(poll.options)

      assert VoteManager.fetch_vote(user["username"], poll.id) == {false, nil}

      assert show_live |> form("#voting-form", option: option.id) |> render_submit()

      new_option =
        Enum.find(Polls.get_poll(poll.id, true).options, nil, fn p_option ->
          option.id == p_option.id
        end)

      assert new_option.votes == 1

      # we confirm that vote manager has the vote
      assert VoteManager.fetch_vote(user["username"], poll.id) == {true, option.id}

      # we confirm that the options are now disabled
      show_live |> element("##{new_option.id}") |> render() =~ "disabled=\"disabled\""
    end
  end

  describe "Show Result" do
    setup [:create_poll]

    test "show result post voting", %{conn: conn, poll: poll, user: user} do
      conn = log_in_user(conn, user)
      option = hd(poll.options)
      # just to set some votes from multiple users
      Enum.map(["user1", "user2"], fn username ->
        {:ok, _} = Polly.VoteSupervisor.start_child(username)
        PollsManager.incr_vote!(poll.id, option.id)
        VoteManager.add_vote(username, poll.id, option.id)
      end)

      {:ok, result_live, _html} = live(conn, ~p"/polls/#{poll}/result")

      # confirm the vote count
      result_live |> element("##{option.id}") |> render() =~
        "<span id=\"#{option.id}\" class=\"px-4 text-s font-normal leading-6 text-center whitespace-nowrap\">\n2\n</span>"
    end
  end
end
