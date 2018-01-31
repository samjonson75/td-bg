use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :trueBG, TrueBGWeb.Endpoint,
  http: [port: 4001],
  server: true

# Hashing algorithm just for testing porpouses
config :trueBG, hashing_module: TrueBG.DummyHashing

# Print only warnings and errors during test
config :logger, handle_sasl_reports: true, level: :warn

# Configure your database
config :trueBG, TrueBG.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "truebg_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
