defmodule PollyWeb.PollLive.Edit do
  use PollyWeb, :live_view

  alias Polly.Polls
  alias Polly.Schema.Poll

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Edit Poll")}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    poll = Polls.get_poll!(id)
    changeset = Polls.change_poll(poll)
    {:noreply, assign(socket, poll: poll, changeset: changeset)}
  end

  @impl true
  def handle_event("save", %{"poll" => poll_params}, socket) do
    case Polls.update_poll(socket.assigns.poll, poll_params) do
      {:ok, _poll} ->
        {:noreply,
         socket
         |> put_flash(:info, "Poll updated successfully")
         |> push_redirect(to: Routes.poll_path(socket, :index))}  # Adjusted to Routes.poll_path/2

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def render(assigns) do
    title_value = Ecto.Changeset.get_field(assigns.changeset, :title)
    description_value = Ecto.Changeset.get_field(assigns.changeset, :description)

    ~H"""
    <.header>
      Edit Poll
    </.header>

    <.simple_form
      for={@changeset}
      id="poll-form"
      phx-submit="save"
    >
      <.input
        field={@changeset}
        name="title"
        type="text"
        label="Title"
        value={title_value}
      />
      <.input
        field={@changeset}
        name="description"
        type="textarea"
        label="Description"
        value={description_value}
      />

      <:actions>
        <.button phx-disable-with="Saving...">Save Poll</.button>
      </:actions>
    </.simple_form>
    """
  end
end
