defmodule Campfire.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos) do
      add :url, :string
      add :bPlayed, :boolean, default: false, null: false
      add :cachedTitle, :string
      add :room_id, references(:rooms, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:videos, [:room_id])
  end
end
