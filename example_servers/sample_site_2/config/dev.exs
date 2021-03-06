use Mix.Config

config :phoenix, SampleSite.Router,
  http: [port: System.get_env("PORT") || 4011],
  debug_errors: true

# Enables code reloading for development
config :phoenix, :code_reloader, true
