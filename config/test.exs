use Mix.Config

config :apartmentex, Apartmentex.TestPostgresRepo,
  hostname: "localhost",
  database: "apartmentex_test",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

config :apartmentex, Ecto.TestRepo,
  url: "ecto://user:pass@local/hello"


config :logger, level: :warn
