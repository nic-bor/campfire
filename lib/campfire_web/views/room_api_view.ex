defmodule CampfireWeb.RoomApiView do
  @doc """
  View for the room API endpoints.
  """

  use CampfireWeb, :view

  @doc """
  Show a single room: render the UUID.
  """
  def render("show.json", %{room: room}) do
    room.uuid
  end

  @doc """
  Show videos: render them in JSON format.
  """
  def render("showvideos.json", %{videos: videos}) do
    videos
  end
end
