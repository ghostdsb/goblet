# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :goblet, GobletWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "V3bj9LE5Kdf6ZQoY8GY7kz3yDvrk0M4cpIa9ImM9GKxYH32LANvjFPRqKX5N5iv/",
  render_errors: [view: GobletWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Goblet.PubSub,
  live_view: [signing_salt: "2879rWpf"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
