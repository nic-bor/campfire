defmodule Campfire.Context.Message do
  @moduledoc """
  Schema for the messages table. Each room can have n chat messages.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Campfire.Context.Room

  schema "messages" do
    field :message, :string
    field :username, :string
    belongs_to :room, Room

    timestamps()
  end

  @doc """
  Selects all messages for a given room ID.
  """
  def for_room(query, id) do
    query
    |> join(:left, [m], r in assoc(m, :room))
    |> where([_, r], r.id == ^id)
    |> select([m, _], m)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:message, :username, :room_id])
    |> cast_assoc(:room)
    |> validate_required([:message, :username, :room_id])
  end
end
