defmodule Campfire.Context.Room do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "rooms" do
    field :name, :string
    field :uuid, Ecto.UUID
    field :isDisabled, :boolean

    timestamps()
  end

  # Queries
  def enabled(query) do
    query
    |> where([q], q.isDisabled == false)
  end

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
