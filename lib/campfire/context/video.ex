defmodule Campfire.Context.Video do
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

  def not_played(query) do
    query
    |> where([q], q.bPlayed == false)
  end

  def played(query) do
    query
    |> where([q], q.bPlayed == true)
  end

  def for_room_uuid(query, uuid) do
    query
    |> join(:left, [v], r in assoc(v, :room))
    |> where([_, r], r.uuid == ^uuid)
    |> select([v, _], v)
  end

  def for_room(query, id) do
    query
    |> join(:left, [v], r in assoc(v, :room))
    |> where([_, r], r.id == ^id)
    |> select([v, _], v)
  end

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
