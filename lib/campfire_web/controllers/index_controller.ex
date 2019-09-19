defmodule CampfireWeb.IndexController do
  @moduledoc """
  Controller for the index page.
  """
  use CampfireWeb, :controller

  @doc """
  Show the index page.
  """
  def index(conn, _params) do
    render(conn, "index.html")
  end
end
