defmodule YoutubesyncWeb.RoomView do
  use YoutubesyncWeb, :view

  def render("show.json", %{room: room}) do
    room.uuid
  end
end