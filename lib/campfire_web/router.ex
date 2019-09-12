defmodule CampfireWeb.Router do
  use CampfireWeb, :router

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

  scope "/", CampfireWeb do
    pipe_through :browser

    get "/", IndexController, :index
    get "/rooms/", RoomController, :index
    get "/rooms/:uuid", RoomController, :show
  end

  scope "/api", CampfireWeb do
    pipe_through :api

    post "/rooms/", RoomController, :create
    post "/rooms/:uuid/videos/:url", RoomController, :add_video
    get "/rooms/:uuid/videos/remaining", RoomController, :get_remaining_videos
  end
end
