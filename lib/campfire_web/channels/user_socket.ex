defmodule CampfireWeb.UserSocket do
  @moduledoc """
  Defines the socket used for the websocket communication inside rooms (see room_channel.ex).
  """

  use Phoenix.Socket

  channel "room:*", CampfireWeb.RoomChannel

  # Augment socket.assigns with the unique token the client generated so we can identify the user in the channel (see room_channel.ex).
  # This type of "auth" essentially identifies browser-tabs and is not tamper proof, but good enough for now.
  def connect(params, socket, connect_info) do
    # Add the ip address (not in use right now)
    ipAddr =
      connect_info.peer_data.address
      |> :inet_parse.ntoa()
      |> to_string

    # Add the user-generated token
    aSocket =
      socket
      |> assign(:ip_addr, ipAddr)
      |> assign(:usertoken, params["usertoken"])

    {:ok, aSocket}
  end

  # !Unexplored - the auto-generated docs follow
  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     CampfireWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
