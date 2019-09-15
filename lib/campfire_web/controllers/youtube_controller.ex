defmodule CampfireWeb.YoutubeController do
  use CampfireWeb, :controller
  import Ecto.Query

  alias Campfire.Context
  alias Campfire.Context.Room
  alias Campfire.Context.Video
  alias Campfire.Repo

  def info(conn, %{"videoid" => videoid}) do
    apiKey = "AIzaSyAQZXgFtTYVp9BnJ5m4StIqnyaYruGqe7c"
    url = "https://www.googleapis.com/youtube/v3/videos?part=snippet%2CcontentDetails%2Cstatistics&fields=items&id=" <> videoid <> "&key=" <> apiKey

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        youtubeInfo = body
        |> Jason.decode
        |> case do {:ok, %{"items" => data}} ->
              data
              |> List.first
              |> case do %{"snippet" => %{"title" => title, "description" => description, "thumbnails" => %{"default" => %{"url" => thumbnailUrl}}}}
                    -> %{title: title, description: description, thumbnailUrl: thumbnailUrl}
                  _ -> %{error: "Video not found."}
                end
           end

        render(conn, "show.json", %{youtubeInfo: youtubeInfo})

      {:ok, resp} ->
        IO.puts "API call successful but bad response:"
        IO.puts resp

      {:error, %{reason: reason}} ->
        IO.puts "API call failed with error:"
        IO.puts reason
    end
  end
end
