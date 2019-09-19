defmodule Campfire.Context.Room do
  @moduledoc """
  Schema for the rooms table. Campfire can have n rooms. Each room can have n chat messages and n videos. Rooms can be disabled which essentially makes them inaccessable (TODO).
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Campfire.Context.Video

  schema "rooms" do
    field :name, :string
    field :uuid, Ecto.UUID
    field :isDisabled, :boolean
    has_many :videos, Video

    timestamps()
  end

  # Queries
  @doc """
  Throws out disabled rooms.
  """
  def enabled(query) do
    query
    |> where([q], q.isDisabled == false)
  end

  @doc """
  Selects a room by a given UUID.
  """
  def with_uuid(query, uuid) do
    query
    |> where([q], q.uuid == ^uuid)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :uuid, :isDisabled])
    |> validate_required([:name])
  end
end
