defmodule Fluid.Router do
  use Fluid.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Fluid do
    pipe_through :browser # Use the default browser stack
    get "/*room_id", PageController, :index
  end

end
