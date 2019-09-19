defmodule Campfire.Context.Video do
  @moduledoc """
  Schema for the videos table. Each room can have n videos. This table is essentially the playlist for the rooms and are sequentially marked as bPlayed. The cached metadata is fetched from the YouTube API.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Campfire.Context.Room

  @derive {Jason.Encoder,
           only: [:id, :bPlayed, :url, :cachedTitle, :cachedDescription, :inserted_at]}

  schema "videos" do
    field :bPlayed, :boolean, default: false
    field :url, :string
    field :cachedTitle, :string
    field :cachedDescription, :string
    belongs_to :room, Room

    timestamps()
  end

  @doc """
  Throws out videos that are already played.
  """
  def not_played(query) do
    query
    |> where([q], q.bPlayed == false)
  end

  @doc """
  Throws out videos that are not played yet.
  """
  def played(query) do
    query
    |> where([q], q.bPlayed == true)
  end

  @doc """
  Selects all videos for a given room UUID.
  """
  def for_room_uuid(query, uuid) do
    query
    |> join(:left, [v], r in assoc(v, :room))
    |> where([_, r], r.uuid == ^uuid)
    |> select([v, _], v)
  end

  @doc """
  Selects all videos for a given room ID.
  """
  def for_room(query, id) do
    query
    |> join(:left, [v], r in assoc(v, :room))
    |> where([_, r], r.id == ^id)
    |> select([v, _], v)
  end

  @doc """
  Selects the oldest unplayed video for a given room ID (e.g. the next video in the room's playlist).
  """
  def current_for_room(query, roomid) do
    query
    |> join(:left, [v], r in assoc(v, :room))
    |> where([_, r], r.id == ^roomid)
    |> select([v, _], v)
    |> not_played
    |> order_by(asc: :id)
    |> limit(1)
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [:url, :bPlayed, :room_id, :cachedTitle, :cachedDescription])
    |> cast_assoc(:room)
    |> validate_required([:url, :bPlayed, :room_id])
  end
end
