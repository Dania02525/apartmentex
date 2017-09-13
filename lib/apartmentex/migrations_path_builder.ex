defmodule Apartmentex.MigrationsPathBuilder do
  import Mix.Ecto, only: [source_repo_priv: 1]
  @migrations_folder Application.get_env(:apartmentex, :migrations_folder) || "tenant_migrations"

  def tenant_migrations_path(repo) do
    Path.join(source_repo_priv(repo), @migrations_folder)
  end
end
