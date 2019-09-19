defmodule CampfireWeb.RoomController do
  @moduledoc """
  Controller for the room page.
  """

  use CampfireWeb, :controller
  import Ecto.Query

  alias Campfire.Context.Room
  alias Campfire.Context.Video
  alias Campfire.Repo

  @doc """
  Shows a single room with room metadata and information about the currently playing video.
  """
  def show(conn, %{"uuid" => uuid}) do
    # Get the requested room.
    room =
      Room
      |> Room.enabled()
      |> Room.with_uuid(uuid)
      |> preload([:videos])
      |> Repo.one()

    # Get the currently playing video for the room.
    initVideo =
      Video
      |> Video.current_for_room(room.id)
      |> Repo.one() ||
        %Video{url: ""}

    render(conn, "show.html", roomInfo: %{room: room, initVideo: initVideo})
  end

  @doc """
  Shows the room index (list of available rooms).
  """
  def index(conn, _params) do
    # Get all enabled rooms.
    rooms =
      Room
      |> Room.enabled()
      |> Repo.all()

    render(conn, "index.html", rooms: rooms)
  end
end
