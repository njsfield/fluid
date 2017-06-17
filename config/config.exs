# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :fluid,
  ecto_repos: [Fluid.Repo]

# Configures the endpoint
config :fluid, Fluid.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Fa4Mmq5dnjZuZ9DpEqQe66RbeGc5nm/9eVAeNs29lcQ2HLajO2rC7tDq08rtzqSK",
  render_errors: [view: Fluid.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Fluid.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Set socket vars
config :fluid, Fluid.Endpoint,
  [socket_url: "ws://localhost:4000/socket/websocket"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
