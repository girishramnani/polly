defmodule PollyWeb.Router do
  use PollyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PollyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PollyWeb do
    pipe_through :browser

    live_session :require_authenticated_user,
      on_mount: [{PollyWeb.UserAuth, :ensure_authenticated}] do
      live "/polls/new", PollLive.Index, :new
      live "/polls/:id/edit", PollLive.Edit, :edit
    end

    live_session :current_user,
      on_mount: [{PollyWeb.UserAuth, :mount_current_user}] do
      live "/", PollLive.Index, :index
      live "/polls/:id", PollLive.Show, :show
      live "/polls/:id/result", PollLive.Show, :show_result
      live "/polls/:id/edit", PollLive.Edit, :edit
    end

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PollyWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/username/log_in", LoginLive.Index, :new
    end

    post "/username/log_in", UserSessionController, :create
    delete "/username/log_out", UserSessionController, :delete
  end

  if Application.compile_env(:polly, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PollyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
