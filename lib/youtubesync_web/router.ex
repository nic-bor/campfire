defmodule YoutubesyncWeb.Router do
  use YoutubesyncWeb, :router

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

  scope "/", YoutubesyncWeb do
    pipe_through :browser

    get "/", IndexController, :index
    get "/rooms/", RoomController, :index
    get "/rooms/:uuid", RoomController, :show
  end

  scope "/api", YoutubesyncWeb do
    pipe_through :api

    post "/rooms/", RoomController, :create
  end
end
