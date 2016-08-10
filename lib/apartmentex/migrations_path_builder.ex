defmodule Apartmentex.MigrationsPathBuilder do
  import Mix.Ecto, only: [build_repo_priv: 1]

  def tenant_migrations_path(repo) do
    Path.join(build_repo_priv(repo), "tenant_migrations")
  end
end
