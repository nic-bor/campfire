defmodule CampfireWeb.RoomChannel do
  use CampfireWeb, :channel

  import Ecto.Query

  alias Campfire.Repo
  alias Campfire.Context
  alias Campfire.Context.Video
  alias Campfire.Context.Message

  def join("room:" <> _room_id, payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    "room:" <> room_id = socket.topic
    Context.get_messages_by_room(room_id)
    |> Enum.each(fn msg -> push(socket, "shout", %{
        username: msg.username,
        message: msg.message,
      }) end)
    {:noreply, socket} # :noreply
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  def handle_in("shout", payload, socket) do
    "room:" <> room_id = socket.topic
    data = Map.put_new(payload, "room_id", room_id)
    Message.changeset(%Message{}, data) |> Repo.insert!
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("addvideo", payload, socket) do
    "room:" <> room_id = socket.topic
    newVid = Map.put_new(payload, "room_id", room_id)

    IO.inspect payload
    # Check if this is actually a youtube video
    case HTTPoison.get(payload["host"] <> "/api/youtube/info/" <> payload["url"]) do
      {:ok, %{status_code: 200, body: body}} ->
        body
        |> Jason.decode
        |> case do {:ok, %{"title" => cachedTitle, "description" => cachedDescription}} ->
            vidWithTitle = Map.put(newVid, "cachedTitle", cachedTitle);
            vidWithDesc = Map.put(vidWithTitle, "cachedDescription", cachedDescription);
            Video.changeset(%Video{}, vidWithDesc) |> Repo.insert!
            videos =
                Video
                |> Video.for_room(room_id)
                |> Video.not_played()
                |> Repo.all

            vidcount = length(videos)
            broadcast socket, "addvideo", %{vidcount: vidcount - 1, username: payload["username"]}
            {:reply, {:ok, %{message: payload["username"] <> " added a video!"}}, socket}
           _ ->
            {:reply, {:error, %{message: "Invalid video ID. Try harder!"}}, socket}
           end
      end
  end

  def handle_in("vid-pause", payload, socket) do
    broadcast socket, "vid-pause", payload
    {:noreply, socket}
  end

  def handle_in("vid-play", payload, socket) do
    broadcast socket, "vid-play", payload
    {:noreply, socket}
  end

  def handle_in("sync-request", payload, socket) do
    broadcast socket, "sync-request", payload
    {:noreply, socket}
  end

  def handle_in("sync-response", payload, socket) do
    broadcast socket, "sync-response", payload
    {:noreply, socket}
  end

  def handle_in("video-ended", payload, socket) do
    "room:" <> room_id = socket.topic

    oldVid = Video
    |> Video.current_for_room(room_id)
    |> where([v], v.url == ^payload["oldUrl"])
    |> Repo.one

    if oldVid != nil do
      oldVid
      |> Ecto.Changeset.change(%{bPlayed: true})
      |> Repo.update!

      newVid = Video
      |> Video.current_for_room(room_id)
      |> Repo.one

      remainingCount = Video
      |> Video.for_room(room_id)
      |> Video.not_played
      |> Repo.all
      |> length

      broadcast socket, "video-play", %{newVid: newVid, oldVid: oldVid, remainingCount: remainingCount - 1, manual: payload["manual"], name: payload["name"]}
    end

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
