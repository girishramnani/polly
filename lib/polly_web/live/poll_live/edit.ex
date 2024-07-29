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
      {:ok, poll} ->
        {:noreply,
         socket
         |> put_flash(:info, "Poll updated successfully")
         |> push_redirect(to: Routes.poll_index_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <.header>
      Edit Poll
    </.header>

    <.simple_form
      for={@changeset}
      id="poll-form"
      phx-target={@myself}
      phx-submit="save"
    >
      <.input field={@changeset[:title]} type="text" label="Title" />
      <.input field={@changeset[:description]} type="textarea" label="Description" />

      <fieldset>
        <legend>Options</legend>
        <%= hidden_input(@changeset, :options, value: "[]") %>
        <%= for f_option <- inputs_for(@changeset, :options) do %>
          <div class="m-4">
            <%= hidden_inputs_for(f_option) %>
            <.input field={f_option[:text]} type="text" />
          </div>
        <% end %>
        <.button id="add-option" type="button" phx-click="add-option" phx-target={@myself}>
          Add
        </.button>
      </fieldset>

      <:actions>
        <.button phx-disable-with="Saving...">Save Poll</.button>
      </:actions>
    </.simple_form>
    """
  end
end
