defmodule YoutubesyncWeb.RoomController do
  use YoutubesyncWeb, :controller

  alias Youtubesync.Context
  alias Youtubesync.Context.Room
  alias Youtubesync.Repo

  def create(conn, _params) do
    with {:ok, %Room{} = room} <- Context.create_room(%{name: "Generic"}) do
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
