use Mix.Config

config :apartmentex, Apartmentex.TestPostgresRepo,
  hostname: "localhost",
  database: "apartmentex_test",
  username: "postgres",
  password: "postgres",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo"

config :apartmentex, Apartmentex.TestMySqlRepo,
  hostname: "localhost",
  database: "apartmentex_test",
  username: "mysql",
  password: "mysql",
  adapter: Ecto.Adapters.MySql,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/repo"

config :logger, level: :warn
