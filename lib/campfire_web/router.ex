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
    get "/rooms/:uuid/videos/remaining", RoomController, :get_remaining_videos
    get "/rooms/:uuid/videos/history", RoomController, :get_video_history
    get "/rooms/:uuid/videos/all", RoomController, :get_all_videos
  end

  scope "/api/youtube", CampfireWeb do
    pipe_through :api

    get "/info/:videoid", YoutubeController, :info
  end
end
