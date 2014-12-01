use Mix.Config

config :phoenix, SampleSite_2.Router,
  http: [port: System.get_env("PORT") || 4001],
