defmodule Campfire.Repo do
  @moduledoc """
  Setup for the Ecto.Repo.
  """

  use Ecto.Repo,
    otp_app: :campfire,
    adapter: Ecto.Adapters.Postgres
end
