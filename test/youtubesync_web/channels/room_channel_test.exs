defmodule CampfireWeb.RoomChannelTest do
  use CampfireWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      socket(CampfireWeb.UserSocket, "user_id", %{some: :assign})
      |> subscribe_and_join(CampfireWeb.RoomChannel, "room:lobby")

    {:ok, socket: socket}
  end

  test "shout broadcasts to room:lobby", %{socket: socket} do
    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast "shout", %{"hello" => "all"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end
end
