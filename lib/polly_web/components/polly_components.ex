defmodule PollyWeb.PollyComponents do
  @moduledoc """

  Components created for use in Polly project.

  """
  use Phoenix.Component

  attr :field, Phoenix.HTML.FormField,
    required: true,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :option, :any,
    required: true,
    doc: "the %Option{} to build the input"

  attr :voted, :boolean,
    default: false,
    doc: "set to true if vote has already been cast"

  attr :selected_option_id, :string, doc: "id of the option that has been selected"

  def vote_option(assigns) do
    ~H"""
    <input
      type="radio"
      id={@option.id}
      name={@field.name}
      value={@option.id}
      class="appearance-none rounded-lg bg-gray-100 cursor-pointer h-full w-full checked:bg-none checked:bg-teal-400 transition-all duration-200 checked:hover:bg-teal-400 hover:bg-gray-200 peer"
      required
      disabled={@voted}
      checked={@voted && @selected_option_id == @option.id}
    />
    <label
      for={@option.id}
      class="absolute top-[50%] left-3 text-gray-400 -translate-y-[50%] peer-checked:text-gray-100 transition-all duration-200"
    >
      <%= @option.text %>
    </label>
    """
  end

  attr :label, :string, default: nil, doc: "labels your result bar"
  attr :value, :integer, default: nil, doc: "adds a value to your result bar"
  attr :max, :integer, default: 100, doc: "sets a max value for your result bar"
  attr :class, :string, default: "", doc: "CSS class"
  attr :id, :string, required: true, doc: "id attached to the value span"
  attr :rest, :global

  def result(assigns) do
    ~H"""
    <h1 class="mb-2"><%= @label %></h1>
    <div {@rest} class={@class}>
      <div class="h-6 rounded-xl flex overflow-hidden">
        <span
          class="bg-teal-400 flex flex-col justify-center"
          style={"width: #{round(@value/@max*100)}%"}
        >
          <span id={@id} class="px-4 text-s font-normal leading-6 text-center whitespace-nowrap">
            <%= @value %>
          </span>
        </span>
      </div>
    </div>
    """
  end
end
