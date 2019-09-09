defmodule Youtubesync.ContextTest do
  use Youtubesync.DataCase

  alias Youtubesync.Context

  describe "rooms" do
    alias Youtubesync.Context.Room

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def room_fixture(attrs \\ %{}) do
      {:ok, room} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Context.create_room()

      room
    end

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Context.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Context.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      assert {:ok, %Room{} = room} = Context.create_room(@valid_attrs)
      assert room.name == "some name"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Context.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      assert {:ok, %Room{} = room} = Context.update_room(room, @update_attrs)
      assert room.name == "some updated name"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Context.update_room(room, @invalid_attrs)
      assert room == Context.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Context.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Context.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Context.change_room(room)
    end
  end

  describe "messages" do
    alias Youtubesync.Context.Message

    @valid_attrs %{message: "some message", username: "some username"}
    @update_attrs %{message: "some updated message", username: "some updated username"}
    @invalid_attrs %{message: nil, username: nil}

    def message_fixture(attrs \\ %{}) do
      {:ok, message} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Context.create_message()

      message
    end

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Context.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Context.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      assert {:ok, %Message{} = message} = Context.create_message(@valid_attrs)
      assert message.message == "some message"
      assert message.username == "some username"
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Context.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      assert {:ok, %Message{} = message} = Context.update_message(message, @update_attrs)
      assert message.message == "some updated message"
      assert message.username == "some updated username"
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Context.update_message(message, @invalid_attrs)
      assert message == Context.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Context.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Context.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Context.change_message(message)
    end
  end

  describe "videos" do
    alias Youtubesync.Context.Video

    @valid_attrs %{bPlayed: true, url: "some url"}
    @update_attrs %{bPlayed: false, url: "some updated url"}
    @invalid_attrs %{bPlayed: nil, url: nil}

    def video_fixture(attrs \\ %{}) do
      {:ok, video} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Context.create_video()

      video
    end

    test "list_videos/0 returns all videos" do
      video = video_fixture()
      assert Context.list_videos() == [video]
    end

    test "get_video!/1 returns the video with given id" do
      video = video_fixture()
      assert Context.get_video!(video.id) == video
    end

    test "create_video/1 with valid data creates a video" do
      assert {:ok, %Video{} = video} = Context.create_video(@valid_attrs)
      assert video.bPlayed == true
      assert video.url == "some url"
    end

    test "create_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Context.create_video(@invalid_attrs)
    end

    test "update_video/2 with valid data updates the video" do
      video = video_fixture()
      assert {:ok, %Video{} = video} = Context.update_video(video, @update_attrs)
      assert video.bPlayed == false
      assert video.url == "some updated url"
    end

    test "update_video/2 with invalid data returns error changeset" do
      video = video_fixture()
      assert {:error, %Ecto.Changeset{}} = Context.update_video(video, @invalid_attrs)
      assert video == Context.get_video!(video.id)
    end

    test "delete_video/1 deletes the video" do
      video = video_fixture()
      assert {:ok, %Video{}} = Context.delete_video(video)
      assert_raise Ecto.NoResultsError, fn -> Context.get_video!(video.id) end
    end

    test "change_video/1 returns a video changeset" do
      video = video_fixture()
      assert %Ecto.Changeset{} = Context.change_video(video)
    end
  end
end
