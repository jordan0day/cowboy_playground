use Mix.Config

# ## SSL Support
#
# To get SSL working, you will need to set:
#
#     https: [port: 443,
#             keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#             certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables point to a file on
# disk for the key and cert.

config :phoenix, SampleSite.Router,
  url: [host: "example.com"],
  http: [port: System.get_env("PORT")],
  secret_key_base: "cs6HeR4zqdvsu93AV+4hW9+fctKOmbA/Yr8ioTQp+g+fnEKG834CmD/hyn98a1NWMy3wCYqfDTrfuyfzyTqYIg=="

config :logger,
  level: :info
