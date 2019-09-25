defmodule CampfireWeb.YoutubeApi do
  @moduledoc """
   Handles Youtube API requests.
  """

  @doc """
  Takes a Youtube Video ID and obtains the video title, description and thumbnail url.
  """
  def get_video_info(videoid) do
    # The quota-limited Api Key used for all api queries. TODO: Provide this via deployment pipeline instead
    apiKey = "AIzaSyAQZXgFtTYVp9BnJ5m4StIqnyaYruGqe7c"

    # Assemble query URL
    url =
      "https://www.googleapis.com/youtube/v3/videos?part=snippet%2CcontentDetails%2Cstatistics&fields=items&id=" <>
        videoid <> "&key=" <> apiKey

    # Send the GET request
    case HTTPoison.get(url) do
      # OK: Parse the info from the body
      {:ok, %{status_code: 200, body: body}} ->
        body
        |> Jason.decode()
        |> case do
          {:ok, %{"items" => data}} ->
            data
            |> List.first()
            |> case do
              %{
                "snippet" => %{
                  "title" => title,
                  "description" => description,
                  "thumbnails" => %{"default" => %{"url" => thumbnailUrl}}
                }
              } ->
                {:ok, %{title: title, description: description, thumbnailUrl: thumbnailUrl}}

              _ ->
                {:error, {:notfound, details: ""}}
            end

          _ ->
            {:error, {:notfound, details: ""}}
        end

      # Request ok but not parsable.
      {:ok, resp} ->
        {:error, {:notparsable, details: resp}}

      # Request error.
      {:error, %{reason: reason}} ->
        {:error, {:requestfailed, details: reason}}
    end
  end
end
