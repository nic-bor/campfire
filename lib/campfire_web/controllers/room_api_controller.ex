defmodule CampfireWeb.RoomApiController do
  @moduledoc """
  Controller for the room API endpoints.
  """

  use CampfireWeb, :controller
  import Ecto.Query

  alias Campfire.Context
  alias Campfire.Context.Room
  alias Campfire.Context.Video
  alias Campfire.Repo

  @doc """
  Creates a new room and shows the UUID of the new room.
  """
  def create(conn, %{"name" => name}) do
    with {:ok, %Room{} = room} <- Context.create_room(%{name: name}) do
      conn
      |> put_status(:created)
      |> render("show.json", room: room)
    end
  end

  @doc """
  Shows all unplayed videos for a given room (including the current one).
  """
  def get_remaining_videos(conn, %{"uuid" => uuid}) do
    videos =
      Video
      |> Video.for_room_uuid(uuid)
      |> Video.not_played()
      |> Repo.all()

    render(conn, "showvideos.json", videos: videos)
  end

  @doc """
  Shows the already-played videos for a given room.
  """
  def get_video_history(conn, %{"uuid" => uuid}) do
    videos =
      Video
      |> Video.for_room_uuid(uuid)
      |> Video.played()
      |> order_by(desc: :id)
      |> Repo.all()

    render(conn, "showvideos.json", videos: videos)
  end

  @doc """
  Shows all videos for a given room (played and unplayed).
  """
  def get_all_videos(conn, %{"uuid" => uuid}) do
    videos =
      Video
      |> Video.for_room_uuid(uuid)
      |> order_by(desc: :id)
      |> Repo.all()

    render(conn, "showvideos.json", videos: videos)
  end
end
