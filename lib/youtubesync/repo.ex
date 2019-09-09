defmodule Youtubesync.Repo do
  use Ecto.Repo,
    otp_app: :youtubesync,
    adapter: Ecto.Adapters.Postgres
end
