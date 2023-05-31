defmodule PollyWeb.LoginLive.Index do
  use PollyWeb, :live_view

  def mount(_params, _session, socket) do
    form = to_form(%{"username" => nil})
    {:ok, assign(socket, form: form)}
  end
end
