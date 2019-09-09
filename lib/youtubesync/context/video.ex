defmodule Youtubesync.Context.Video do
  use Ecto.Schema
  import Ecto.Changeset

  schema "videos" do
    field :bPlayed, :boolean, default: false
    field :url, :string
    field :room_id, :id

    timestamps()
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [:url, :bPlayed])
    |> validate_required([:url, :bPlayed])
  end
end
