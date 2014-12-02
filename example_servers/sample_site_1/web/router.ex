defmodule SampleSite.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ~w(html)
    plug :fetch_session
  end

  pipeline :api do
    #plug :accepts, ~w(json)
  end

  # scope "/", SampleSite do
  #   pipe_through :browser # Use the default browser stack

  #   get "/", PageController, :index
  # end

  # Other scopes may use custom stacks.
  scope "/", SampleSite do
    pipe_through :api

    get "/", ApiController, :index

    get "/:path_param", ApiController, :show

    post "/", ApiController, :handle_post

    put "/", ApiController, :handle_put

    delete "/", ApiController, :handle_delete

    patch "/", ApiController, :handle_patch

    options "/", ApiController, :handle_options
  end
end
