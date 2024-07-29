defmodule PollyWeb.PollLive.FormComponent do
  use PollyWeb, :live_component

  alias Polly.Polls
  alias Polly.Schema.Poll

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Create a New Poll</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="poll-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <fieldset>
          <legend>Options</legend>
          <%= hidden_input(@form, :options, value: "[]") %>
          <%= for f_option <- inputs_for(@form, :options) do %>
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
    </div>
    """
  end

  @impl true
  def update(%{poll: poll} = assigns, socket) do
    changeset = Poll.changeset(poll)
    existing = Ecto.Changeset.get_field(changeset, :options, [])
    new_changeset = Ecto.Changeset.put_embed(changeset, :options, existing ++ [%{}])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, new_changeset)
     |> assign_form(changeset)}
  end

  def handle_event("add-option", _, socket) do
    socket =
      update(socket, :changeset, fn changeset ->
        existing = Ecto.Changeset.get_field(changeset, :options, [])
        Ecto.Changeset.put_embed(changeset, :options, existing ++ [%{}])
      end)

    dbg(socket.assigns)
    socket = assign(socket, :form, to_form(socket.assigns.changeset))

    {:noreply, socket}
  end

  def handle_event("delete-option", %{"index" => index}, socket) do
    index = String.to_integer(index)

    socket =
      update(socket, :changeset, fn changeset ->
        existing = Ecto.Changeset.get_field(changeset, :options, [])
        Ecto.Changeset.put_embed(changeset, :options, List.delete_at(existing, index))
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"poll" => poll_params}, socket) do
    changeset =
      socket.assigns.poll
      |> Poll.changeset(poll_params)
      |> Map.put(:action, :validate)

    socket = socket |> update(:changeset, fn _changeset -> changeset end)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"poll" => poll_params}, socket) do
    save_poll(socket, socket.assigns.action, poll_params)
  end


  defp save_poll(socket, :new, poll_params) do
    poll_params
    |> Map.merge(%{"creator_username" => socket.assigns[:current_user]})
    |> Polls.create_poll()
    |> case do
      {:ok, poll} ->
        notify_parent({:saved, poll})

        {:noreply,
         socket
         |> put_flash(:info, "Poll created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_poll(socket, :edit, poll_params) do
    Polly.Polls.update_poll(socket.assigns.poll.id, poll_params)
    |> case do
      {:ok, poll} ->
        notify_parent({:saved, poll})

        {:noreply,
         socket
         |> put_flash(:info, "Poll updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end


  defp assign_form(socket, changeset) do
    socket
    |> assign(:form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
