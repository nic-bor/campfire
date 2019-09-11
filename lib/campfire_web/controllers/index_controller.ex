defmodule CampfireWeb.IndexController do
  use CampfireWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
