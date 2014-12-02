use Mix.Config

config :cowboy_playground, httpoison_config: [hackney: [proxy: {"ps-auto.proxy.lexmark.com", 80}]]

config :logger, :console,
  level: :info