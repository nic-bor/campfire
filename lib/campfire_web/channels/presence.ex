defmodule CampfireWeb.Presence do
  @moduledoc """
  Presence tracking for viewing room participants. Uses OOB configuration.
  """

  use Phoenix.Presence,
    otp_app: :campfire,
    pubsub_server: Campfire.PubSub
end
