defmodule PollyWeb.PollLive.Edit do
  use PollyWeb, :live_view

  alias Polly.Polls
  alias Polly.Schema.Poll
  alias Polly.Schema.Option

  @impl true
  def mount(_params, %{"user_token" => user_token} = session, socket) do
    IO.inspect(session, label: "Mount session")
    IO.inspect(socket, label: "Mount socket")

    case get_user_by_token(user_token) do
      nil ->
        {:error, :unauthorized}

      current_user ->
        socket =
          socket
          |> assign(:current_user, current_user)
          |> assign(:page_title, "Edit Poll")

        {:ok, socket}
    end
  end

  defp get_user_by_token(user_token) do
    case :ets.lookup(:users, user_token) do
      [{^user_token, user}] -> user
      [] -> nil
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    case Polls.get_poll!(id) do
      %Poll{} = poll ->
        changeset = Polls.change_poll(poll)
        {:noreply, assign(socket, poll: poll, changeset: changeset, form: to_form(changeset))}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Poll not found")
         |> push_redirect(to: "/polls")}
    end
  end

  @impl true
  def handle_event("save", %{"poll" => poll_params}, socket) do
    case Polls.update_poll(socket.assigns.poll, poll_params) do
      {:ok, poll} ->
        socket =
          socket
          |> put_flash(:info, "Poll updated successfully")
          |> assign(:poll, poll)
          |> push_redirect(to: "/polls")

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

        <.button id="add-option" type="button" phx-click="add-option">
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
