# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :youtubesync,
  ecto_repos: [Youtubesync.Repo]

# Configures the endpoint
config :youtubesync, YoutubesyncWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "uBV3J9YyEnn3nGJDgTfTBTtJfWbmbjOeu0QQ5YH3T3RTj8Jnl+FHK4wfjdw9zap7",
  render_errors: [view: YoutubesyncWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Youtubesync.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
