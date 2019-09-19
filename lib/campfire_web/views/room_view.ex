defmodule CampfireWeb.RoomView do
  use CampfireWeb, :view

  def render("show.json", %{room: room}) do
    room.uuid
  end

  def render("showvideos.json", %{videos: videos}) do
    videos
  end
end
