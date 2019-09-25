defmodule CampfireWeb.RoomChannel do
  @moduledoc """
  The central channel used for websocket communication. Synchronizes chat messages, presence and video playback.
  """

  use CampfireWeb, :channel

  import Ecto.Query

  alias Campfire.Repo
  alias Campfire.Context.Video
  alias Campfire.Context.Message
  alias CampfireWeb.Presence

  @doc """
  Adds a new user to the channel. No auth is used at the moment.
  """
  def join("room:" <> _room_id, _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  @doc """
  Hook for post-join events. Performs presence tracking and feeds the history of chat messages to the new client.
  """
  def handle_info(:after_join, socket) do
    "room:" <> room_id = socket.topic

    # Send presence event
    push(socket, "presence_state", Presence.list(socket))

    # Track new user's presence
    {:ok, _} =
      Presence.track(socket, socket.assigns.usertoken, %{
        online_at: inspect(System.system_time(:second))
      })

    # Send chat message history to the new client
    Message
    |> Message.for_room(room_id)
    |> order_by(desc: :id)
    |> limit(50)
    |> Repo.all()
    |> Enum.sort()
    |> Enum.each(fn msg ->
      push(socket, "shout", %{
        username: msg.username,
        message: msg.message,
        timestamp: msg.inserted_at
      })
    end)

    {:noreply, socket}
  end

  @doc """
  Shout: Receives chat messages, writes them to the databse and broadcasts them to the client.
  Rate-Limited per usertoken (e.g. browser tab).
  """
  def handle_in("shout", payload, socket) do
    # Parse the room we're in
    "room:" <> room_id = socket.topic

    # Rate-Limit
    case Hammer.check_rate("shout#" <> socket.assigns.usertoken, 2000, 2) do
      {:deny, _} ->
        {:reply,
         {:error, %{message: "You're going a bit too fast. Try again in a couple seconds."}},
         socket}

      {:allow, _} ->
        # Supplement the current room id to the message and insert into database
        data = Map.put_new(payload, "room_id", room_id)
        Message.changeset(%Message{}, data) |> Repo.insert!()

        # Broadcast the new message to all clients
        broadcast(socket, "shout", payload)
        {:reply, {:ok, %{message: "OK"}}, socket}
    end
  end

  @doc """
  VidAdd: A client wants to add a new video. Expects a YouTube Video ID which is sent to the YouTube API for verification and retrieval of video metadata.
  Rate-Limited per usertoken (e.g. browser tab).
  """
  def handle_in("vid-add", payload, socket) do
    # Parse the room we're in
    "room:" <> room_id = socket.topic

    # Rate-Limit
    case Hammer.check_rate("vid-add#" <> socket.assigns.usertoken, 5000, 1) do
      {:deny, _} ->
        {:reply,
         {:error, %{message: "You're going a bit too fast. Try again in a couple seconds."}},
         socket}

      {:allow, _} ->
        # Attempt to fetch YouTube metadata. If this fails, it's probably not a valid video ID :-)
        case HTTPoison.get(payload["host"] <> "/api/youtube/info/" <> payload["url"]) do
          {:ok, %{status_code: 200, body: body}} ->
            body
            |> Jason.decode()
            |> case do
              {:ok, %{"title" => cachedTitle, "description" => cachedDescription}} ->
                # GET was successful: Parse out the video info and insert the new video into the database.
                newVid =
                  payload
                  |> Map.put_new("room_id", room_id)
                  |> Map.put_new("cachedTitle", cachedTitle)
                  |> Map.put_new("cachedDescription", cachedDescription)

                Video.changeset(%Video{}, newVid) |> Repo.insert!()

                # Count the number of remaining videos
                remainingCount =
                  Video
                  |> Video.for_room(room_id)
                  |> Video.not_played()
                  |> Repo.all()
                  |> length

                # Broadcast the number of remaining videos (minus the current one) and the name of the user who inserted it.
                broadcast(socket, "vid-add", %{
                  vidcount: remainingCount - 1,
                  username: payload["username"]
                })

                {:reply, {:ok, %{message: "Video added!"}}, socket}

              _ ->
                {:reply, {:error, %{message: "Invalid video ID. Try harder!"}}, socket}
            end
        end
    end
  end

  @doc """
  VidPause: User pressed Pause on the player. Simply broadcast this to all clients.
  """
  def handle_in("vid-pause", payload, socket) do
    broadcast(socket, "vid-pause", payload)
    {:noreply, socket}
  end

  @doc """
  VidPlay: User pressed Play on the player. Simply broadcast this to all clients.
  """
  def handle_in("vid-play", payload, socket) do
    broadcast(socket, "vid-play", payload)
    {:noreply, socket}
  end

  @doc """
  SyncRequest: A User wishes to get the current video state (e.g. he just joined). Forward this request to all clients so they can reply.
  """
  def handle_in("sync-request", payload, socket) do
    broadcast(socket, "sync-request", payload)
    {:noreply, socket}
  end

  @doc """
  SyncResponse: A User answers a SyncRequest (see above). Forward the response to all clients (correlating this to the actual client who sent the request is left to client-side code).
  """
  def handle_in("sync-response", payload, socket) do
    broadcast(socket, "sync-response", payload)
    {:noreply, socket}
  end

  @doc """
  VideoEnded: The player has reached the final frame for a client or client manually skipped the video (in both cases, the next video should be played). Load the next video from the DB, push it to the clients and mark the current one as bPlayed.
  """
  def handle_in("vid-ended", payload, socket) do
    "room:" <> room_id = socket.topic

    # To prevent timing issues (e.g. clients sending vid-ended with a slight delay), the client must explicitly state the video he wishes to end.
    oldVid =
      Video
      |> Video.current_for_room(room_id)
      |> where([v], v.url == ^payload["oldUrl"])
      |> Repo.one()

    # Proceed only if the vid received from the client is the one actually currently playing.
    if oldVid != nil do
      # Mark the old video as played:
      oldVid
      |> Ecto.Changeset.change(%{bPlayed: true})
      |> Repo.update!()

      # Get the new video from the database.
      newVid =
        Video
        |> Video.current_for_room(room_id)
        |> Repo.one()

      # Determine the number of remaining videos
      remainingCount =
        Video
        |> Video.for_room(room_id)
        |> Video.not_played()
        |> Repo.all()
        |> length

      # Push both the old and the new video info the the clients as well as the number of remaining videos (as with AddVideo, minus the currently playing one).
      # Also tell clients who inserted the video and whether or not the client triggered vid-ended automatically (last frame reached) or manually ("Skip" button).
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
end
