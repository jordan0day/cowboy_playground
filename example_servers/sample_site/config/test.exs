use Mix.Config

config :phoenix, SampleSite.Router,
  http: [port: System.get_env("PORT") || 4001],
