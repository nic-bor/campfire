defmodule CampfireWeb.RoomController do
  use CampfireWeb, :controller
  import Ecto.Query

  alias Campfire.Context
  alias Campfire.Context.Room
  alias Campfire.Context.Video
  alias Campfire.Repo

  def create(conn, %{"name" => name}) do
    with {:ok, %Room{} = room} <- Context.create_room(%{name: name}) do
      conn
      |> put_status(:created)
      |> render("show.json", room: room)
    end
  end

  def add_video(conn, %{"uuid" => uuid, "url" => url}) do
    room = Room
      |> Room.enabled
      |> Room.with_uuid(uuid)
      |> Repo.one

    with {:ok, %Video{} = video} <- Context.create_video(%{url: url, room_id: room.id}) do
      conn
      |> send_resp(:created, "OK")
    else {:error, _} ->
      conn
      |> send_resp(:internal_server_error, "NOK")
    end
  end

  def get_remaining_videos(conn, %{"uuid" => uuid}) do
    videos = Video
      |> Video.for_room_uuid(uuid)
      |> Video.not_played()
      |> Repo.all

      render(conn, "showvideos.json", videos: videos)
  end


  def show(conn, %{"uuid" => uuid}) do
    room = Room
      |> Room.enabled
      |> Room.with_uuid(uuid)
      |> preload([:videos])
      |> Repo.one

    initVideo = Video
    |> Video.current_for_room(room.id)
    |> Repo.one
    || %Video{url: ""}

    render(conn, "show.html", roomInfo: %{room: room, initVideo: initVideo})
  end

  def index(conn, _params) do
    rooms = Room
      |> Room.enabled
      |> Repo.all

    render(conn, "index.html", rooms: rooms)
  end
end
