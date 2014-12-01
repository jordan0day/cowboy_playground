# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the router
config :phoenix, SampleSite_2.Router,
  url: [host: "localhost"],
  http: [port: System.get_env("PORT")],
  secret_key_base: "7czlF7Cqcc1YxyIhaC5GFXHpLwYabWjsvQl+R0Kpc6RhE0qvWaTL1yjsffkmi98LCYrKwJUUaKWThMIdHwW/Fg==",
  debug_errors: false,
  error_controller: SampleSite_2.PageController

# Session configuration
config :phoenix, SampleSite_2.Router,
  session: [store: :cookie,
            key: "_sample_site_2_key"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
