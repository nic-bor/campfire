defmodule CampfireWeb.RoomChannel do
  use CampfireWeb, :channel

  import Ecto.Query

  alias Campfire.Repo
  alias Campfire.Context
  alias Campfire.Context.Video
  alias Campfire.Context.Message
  alias CampfireWeb.Presence

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

    push(socket, "presence_state", Presence.list(socket))

    {:ok, _} =
      Presence.track(socket, socket.assigns.usertoken, %{
        online_at: inspect(System.system_time(:second))
      })

    Context.get_messages_by_room(room_id)
    |> Enum.each(fn msg ->
      push(socket, "shout", %{
        username: msg.username,
        message: msg.message,
        timestamp: msg.inserted_at
      })
    end)

    # :noreply
    {:noreply, socket}
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

    # Rate-Limit
    case Hammer.check_rate("shout#" <> socket.assigns.usertoken, 2000, 2) do
      {:deny, _} ->
        {:reply,
         {:error, %{message: "You're going a bit too fast. Try again in a couple seconds."}},
         socket}

      {:allow, _} ->
        data = Map.put_new(payload, "room_id", room_id)
        Message.changeset(%Message{}, data) |> Repo.insert!()
        broadcast(socket, "shout", payload)
        {:reply, {:ok, %{message: "OK"}}, socket}
    end
  end

  def handle_in("vid-add", payload, socket) do
    "room:" <> room_id = socket.topic
    newVid = Map.put_new(payload, "room_id", room_id)

    # Rate-Limit
    case Hammer.check_rate("vid-add#" <> socket.assigns.usertoken, 5000, 1) do
      {:deny, _} ->
        {:reply,
         {:error, %{message: "You're going a bit too fast. Try again in a couple seconds."}},
         socket}

      {:allow, _} ->
        # Check if this is actually a youtube video
        case HTTPoison.get(payload["host"] <> "/api/youtube/info/" <> payload["url"]) do
          {:ok, %{status_code: 200, body: body}} ->
            body
            |> Jason.decode()
            |> case do
              {:ok, %{"title" => cachedTitle, "description" => cachedDescription}} ->
                vidWithTitle = Map.put(newVid, "cachedTitle", cachedTitle)
                vidWithDesc = Map.put(vidWithTitle, "cachedDescription", cachedDescription)
                Video.changeset(%Video{}, vidWithDesc) |> Repo.insert!()

                videos =
                  Video
                  |> Video.for_room(room_id)
                  |> Video.not_played()
                  |> Repo.all()

                vidcount = length(videos)

                broadcast(socket, "vid-add", %{
                  vidcount: vidcount - 1,
                  username: payload["username"]
                })

                {:reply, {:ok, %{message: "Video added!"}}, socket}

              _ ->
                {:reply, {:error, %{message: "Invalid video ID. Try harder!"}}, socket}
            end
        end
    end
  end

  def handle_in("vid-pause", payload, socket) do
    broadcast(socket, "vid-pause", payload)
    {:noreply, socket}
  end

  def handle_in("vid-play", payload, socket) do
    broadcast(socket, "vid-play", payload)
    {:noreply, socket}
  end

  def handle_in("sync-request", payload, socket) do
    broadcast(socket, "sync-request", payload)
    {:noreply, socket}
  end

  def handle_in("sync-response", payload, socket) do
    broadcast(socket, "sync-response", payload)
    {:noreply, socket}
  end

  def handle_in("vid-ended", payload, socket) do
    "room:" <> room_id = socket.topic

    oldVid =
      Video
      |> Video.current_for_room(room_id)
      |> where([v], v.url == ^payload["oldUrl"])
      |> Repo.one()

    if oldVid != nil do
      oldVid
      |> Ecto.Changeset.change(%{bPlayed: true})
      |> Repo.update!()

      newVid =
        Video
        |> Video.current_for_room(room_id)
        |> Repo.one()

      remainingCount =
        Video
        |> Video.for_room(room_id)
        |> Video.not_played()
        |> Repo.all()
        |> length

      broadcast(socket, "vid-new", %{
        newVid: newVid,
        oldVid: oldVid,
        remainingCount: remainingCount - 1,
        manual: payload["manual"],
        name: payload["name"]
      })
    end

    {:noreply, socket}
  end

  # No authorization logic (for now)
  defp authorized?(_payload) do
    true
  end
end
