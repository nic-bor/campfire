defmodule Campfire.Context do
  @moduledoc """
  Contains CRUD helpers for the database.
  """

  import Ecto.Query, warn: false
  alias Campfire.Repo

  alias Campfire.Context.Room
  alias Campfire.Context.Message
  alias Campfire.Context.Video

  # Rooms
  def list_rooms do
    Repo.all(Room)
  end

  def get_room!(id), do: Repo.get!(Room, id)

  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  def change_room(%Room{} = room) do
    Room.changeset(room, %{})
  end

  # Messages
  def list_messages do
    Repo.all(Message)
  end

  def get_message!(id), do: Repo.get!(Message, id)

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  # Videos
  def list_videos do
    Repo.all(Video)
  end

  def get_video!(id), do: Repo.get!(Video, id)

  def create_video(attrs \\ %{}) do
    %Video{}
    |> Video.changeset(attrs)
    |> Repo.insert()
  end

  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  def change_video(%Video{} = video) do
    Video.changeset(video, %{})
  end
end
