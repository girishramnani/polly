defmodule PollyWeb.PollLive.Edit do
  use PollyWeb, :live_view

  alias Polly.Polls
  alias Polly.Schema.Option

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Edit Poll")}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    poll = Polls.get_poll!(id)
    changeset = Polls.change_poll(poll)
    {:noreply, assign(socket, poll: poll, changeset: changeset, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"poll" => poll_params}, socket) do
    case Polls.update_poll(socket.assigns.poll, poll_params) do
      {:ok, poll} ->
        socket =
          socket
          |> put_flash(:info, "Poll updated successfully")
          |> assign(:poll, poll)
          |> push_redirect(to: "/")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("add-option", _, socket) do
    socket =
      update(socket, :changeset, fn changeset ->
        existing = Ecto.Changeset.get_field(changeset, :options, [])
        new_option_changeset = %Option{} |> Ecto.Changeset.change()

        new_option_changeset =
          Ecto.Changeset.put_change(new_option_changeset, :text, "New Option Text")

        Ecto.Changeset.put_embed(changeset, :options, existing ++ [new_option_changeset])
      end)

    socket = assign(socket, :form, to_form(socket.assigns.changeset))
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Edit Poll
    </.header>

    <.simple_form for={@form} id="poll-form" phx-submit="save">
      <.input
        field={@form[:title]}
        name="title"
        type="text"
        label="Title"
        value={Phoenix.HTML.Form.input_value(@form, :title)}
      />
      <.input
        field={@form[:description]}
        name="description"
        type="textarea"
        label="Description"
        value={Phoenix.HTML.Form.input_value(@form, :description)}
      />
      <fieldset>
        <legend>Options</legend>
         <%= hidden_input(@form, :options, value: "[]") %>
        <%= for option_form <- inputs_for(@form, :options) do %>
          <div class="m-4">
            <%= hidden_inputs_for(option_form) %>
            <input
              type="text"
              name={option_form[:text].name}
              value={Phoenix.HTML.Form.input_value(option_form, :text)}
            />
          </div>
        <% end %>
        
        <.button id="add-option" phx-click="add-option">Add Option</.button>
      </fieldset>
      
      <:actions>
        <.button type="submit">Save</.button>
      </:actions>
    </.simple_form>
    """
  end
end
