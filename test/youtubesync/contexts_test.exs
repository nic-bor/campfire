defmodule Youtubesync.ContextsTest do
  use Youtubesync.DataCase

  alias Youtubesync.Contexts

  describe "messages" do
    alias Youtubesync.Contexts.Messages

    @valid_attrs %{message: "some message", username: "some username"}
    @update_attrs %{message: "some updated message", username: "some updated username"}
    @invalid_attrs %{message: nil, username: nil}

    def messages_fixture(attrs \\ %{}) do
      {:ok, messages} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Contexts.create_messages()

      messages
    end

    test "list_messages/0 returns all messages" do
      messages = messages_fixture()
      assert Contexts.list_messages() == [messages]
    end

    test "get_messages!/1 returns the messages with given id" do
      messages = messages_fixture()
      assert Contexts.get_messages!(messages.id) == messages
    end

    test "create_messages/1 with valid data creates a messages" do
      assert {:ok, %Messages{} = messages} = Contexts.create_messages(@valid_attrs)
      assert messages.message == "some message"
      assert messages.username == "some username"
    end

    test "create_messages/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contexts.create_messages(@invalid_attrs)
    end

    test "update_messages/2 with valid data updates the messages" do
      messages = messages_fixture()
      assert {:ok, %Messages{} = messages} = Contexts.update_messages(messages, @update_attrs)
      assert messages.message == "some updated message"
      assert messages.username == "some updated username"
    end

    test "update_messages/2 with invalid data returns error changeset" do
      messages = messages_fixture()
      assert {:error, %Ecto.Changeset{}} = Contexts.update_messages(messages, @invalid_attrs)
      assert messages == Contexts.get_messages!(messages.id)
    end

    test "delete_messages/1 deletes the messages" do
      messages = messages_fixture()
      assert {:ok, %Messages{}} = Contexts.delete_messages(messages)
      assert_raise Ecto.NoResultsError, fn -> Contexts.get_messages!(messages.id) end
    end

    test "change_messages/1 returns a messages changeset" do
      messages = messages_fixture()
      assert %Ecto.Changeset{} = Contexts.change_messages(messages)
    end
  end

  describe "videos" do
    alias Youtubesync.Contexts.Videos

    @valid_attrs %{bPlayed: true, url: "some url"}
    @update_attrs %{bPlayed: false, url: "some updated url"}
    @invalid_attrs %{bPlayed: nil, url: nil}

    def videos_fixture(attrs \\ %{}) do
      {:ok, videos} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Contexts.create_videos()

      videos
    end

    test "list_videos/0 returns all videos" do
      videos = videos_fixture()
      assert Contexts.list_videos() == [videos]
    end

    test "get_videos!/1 returns the videos with given id" do
      videos = videos_fixture()
      assert Contexts.get_videos!(videos.id) == videos
    end

    test "create_videos/1 with valid data creates a videos" do
      assert {:ok, %Videos{} = videos} = Contexts.create_videos(@valid_attrs)
      assert videos.bPlayed == true
      assert videos.url == "some url"
    end

    test "create_videos/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contexts.create_videos(@invalid_attrs)
    end

    test "update_videos/2 with valid data updates the videos" do
      videos = videos_fixture()
      assert {:ok, %Videos{} = videos} = Contexts.update_videos(videos, @update_attrs)
      assert videos.bPlayed == false
      assert videos.url == "some updated url"
    end

    test "update_videos/2 with invalid data returns error changeset" do
      videos = videos_fixture()
      assert {:error, %Ecto.Changeset{}} = Contexts.update_videos(videos, @invalid_attrs)
      assert videos == Contexts.get_videos!(videos.id)
    end

    test "delete_videos/1 deletes the videos" do
      videos = videos_fixture()
      assert {:ok, %Videos{}} = Contexts.delete_videos(videos)
      assert_raise Ecto.NoResultsError, fn -> Contexts.get_videos!(videos.id) end
    end

    test "change_videos/1 returns a videos changeset" do
      videos = videos_fixture()
      assert %Ecto.Changeset{} = Contexts.change_videos(videos)
    end
  end
end
