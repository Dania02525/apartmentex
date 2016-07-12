Code.require_file "./test_repo.exs", __DIR__

defmodule Apartmentex.TestPostgresRepo do
  use Ecto.Repo, otp_app: :apartmentex, adapter: Ecto.Adapters.Postgres
end

Mix.Task.run "ecto.drop", ["quiet", "-r", "Apartmentex.TestPostgresRepo"]
Mix.Task.run "ecto.create", ["quiet", "-r", "Apartmentex.TestPostgresRepo"]

Apartmentex.TestPostgresRepo.start_link

ExUnit.start()

Ecto.Adapters.SQL.begin_test_transaction(Apartmentex.TestPostgresRepo)
