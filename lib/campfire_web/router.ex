defmodule CampfireWeb.Router do
  @moduledoc """
  The router module for both the browser and API endpoints.
  """
  use CampfireWeb, :router

  # Pipelines
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

  # Scopes
  # Browser
  scope "/", CampfireWeb do
    pipe_through :browser

    get "/", IndexController, :index
    get "/rooms/", RoomController, :index
    get "/rooms/:uuid", RoomController, :show
  end

  # API
  scope "/api", CampfireWeb do
    pipe_through :api

    post "/rooms/", RoomApiController, :create
    get "/rooms/:uuid/videos/remaining", RoomApiController, :get_remaining_videos
    get "/rooms/:uuid/videos/history", RoomApiController, :get_video_history
    get "/rooms/:uuid/videos/all", RoomApiController, :get_all_videos
  end
end
