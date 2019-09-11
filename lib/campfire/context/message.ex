defmodule Campfire.Context.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :message, :string
    field :username, :string
    field :room_id, :id

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:message, :username, :room_id])
    |> validate_required([:message, :username, :room_id])
  end
end
