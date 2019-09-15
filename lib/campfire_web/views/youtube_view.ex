defmodule CampfireWeb.YoutubeView do
  use CampfireWeb, :view

  def render("show.json", %{youtubeInfo: ytInfo}) do
    ytInfo
  end
end