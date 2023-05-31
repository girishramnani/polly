defmodule PollyWeb.PollLive.Index do
  use PollyWeb, :live_view

  alias Polly.Polls
  alias Polly.Schema.Poll

  @topic Polly.Constants.encode(:polls_topic)
  @new_poll_event Polly.Constants.encode(:new_poll_event)

  @impl true
  def mount(_params, _session, socket) do
    # we subscribe to a topic for the index page, this way
    # when someone votes we could update this page
    PollyWeb.Endpoint.subscribe(@topic)

    # Though of using streams here but as per chris Mccord's
    # recent comment streams dont support a full update i.e.
    # cannot replace a stream with a new stream
    {:ok, assign(socket, :polls, Polls.list_polls())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Poll")
    |> assign(:poll, %Poll{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Polls")
    |> assign(:poll, nil)
  end

  @impl true
  def handle_info(%{topic: @topic, payload: _state}, socket) do
    # we basically update the whole list of polls
    {:noreply, update(socket, :polls, fn _polls -> Polls.list_polls() end)}
  end

  @impl true
  def handle_info({PollyWeb.PollLive.FormComponent, {:saved, poll}}, socket) do
    # broadcast a new poll event so other users can see updated poll list
    # in real time
    PollyWeb.Endpoint.broadcast(@topic, @new_poll_event, poll)
    {:noreply, update(socket, :polls, fn _polls -> Polls.list_polls() end)}
  end
end
