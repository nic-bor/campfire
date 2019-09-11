defmodule CampfireWeb.RoomView do
  use CampfireWeb, :view

  def render("show.json", %{room: room}) do
    room.uuid
  end
end