defmodule YoutubesyncWeb.IndexController do
  use YoutubesyncWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
