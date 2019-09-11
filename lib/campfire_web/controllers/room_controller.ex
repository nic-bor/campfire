defmodule CampfireWeb.RoomController do
  use CampfireWeb, :controller

  alias Campfire.Context
  alias Campfire.Context.Room
  alias Campfire.Repo

  def create(conn, %{"name" => name}) do
    with {:ok, %Room{} = room} <- Context.create_room(%{name: name}) do
      conn
      |> put_status(:created)
      |> render("show.json", room: room)
    end
  end

  def show(conn, %{"uuid" => uuid}) do
    room = Room
      |> Room.enabled
      |> Room.with_uuid(uuid)
      |> Repo.one

    render(conn, "show.html", room: room)
  end

  def index(conn, _params) do
    rooms = Room
      |> Room.enabled
      |> Repo.all

    render(conn, "index.html", rooms: rooms)
  end
end
