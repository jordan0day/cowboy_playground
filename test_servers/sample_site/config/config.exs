# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the router
config :phoenix, SampleSite.Router,
  url: [host: "localhost"],
  http: [port: System.get_env("PORT")],
  secret_key_base: "cs6HeR4zqdvsu93AV+4hW9+fctKOmbA/Yr8ioTQp+g+fnEKG834CmD/hyn98a1NWMy3wCYqfDTrfuyfzyTqYIg==",
  debug_errors: false,
  error_controller: SampleSite.PageController

# Session configuration
config :phoenix, SampleSite.Router,
  session: [store: :cookie,
            key: "_sample_site_key"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
