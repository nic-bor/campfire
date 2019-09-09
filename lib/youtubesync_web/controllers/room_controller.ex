defmodule YoutubesyncWeb.RoomController do
  use YoutubesyncWeb, :controller

  alias Youtubesync.Context
  alias Youtubesync.Context.Room

  def create(conn, _params) do
    with {:ok, %Room{} = room} <- Context.create_room(%{name: "Generic"}) do
      conn
      |> put_status(:created)
      |> render("show.json", room: room)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.html", id: id)
  end

  def index(conn, _params) do
    rooms = Context.list_rooms()
    render(conn, "index.html", rooms: rooms)
  end
end
