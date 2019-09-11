defmodule CampfireWeb.RoomChannel do
  use CampfireWeb, :channel

  alias Campfire.Context

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
    Context.Message.changeset(%Context.Message{}, data) |> Campfire.Repo.insert!
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("addvideo", payload, socket) do
    "room:" <> room_id = socket.topic
    data = Map.put_new(payload, "room_id", room_id)
    Context.Video.changeset(%Context.Video{}, data) |> Campfire.Repo.insert!
    broadcast socket, "addvideo", %{}
    {:noreply, socket}
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

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
