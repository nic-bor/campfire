defmodule Campfire.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string
      add :uuid, :uuid, default: fragment("uuid_generate_v4()")
      add :isDisabled, :boolean, default: false

      timestamps()
    end
  end
end
