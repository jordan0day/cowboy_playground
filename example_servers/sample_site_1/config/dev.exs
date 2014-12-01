use Mix.Config

config :phoenix, SampleSite.Router,
  http: [port: System.get_env("PORT") || 4010],
  debug_errors: true

# Enables code reloading for development
config :phoenix, :code_reloader, true
