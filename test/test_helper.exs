defmodule Apartmentex.TestPostgresRepo do
  use Ecto.Repo, otp_app: :apartmentex, adapter: Ecto.Adapters.Postgres, pool: Ecto.Adapters.SQL.Sandbox
end

Code.compiler_options(ignore_module_conflict: true)

Mix.Task.run "ecto.drop", ["quiet", "-r", "Apartmentex.TestPostgresRepo"]
Mix.Task.run "ecto.create", ["quiet", "-r", "Apartmentex.TestPostgresRepo"]

Apartmentex.TestPostgresRepo.start_link
Ecto.TestRepo.start_link(url: "ecto://user:pass@local/hello")

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Apartmentex.TestPostgresRepo, :manual)
