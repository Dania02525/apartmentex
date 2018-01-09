defmodule Apartmentex.MigrationsPathBuilder do
  @migrations_folder Application.get_env(:apartmentex, :migrations_folder) || "tenant_migrations"

  def tenant_migrations_path(repo) do
    Path.join(priv_path_for(repo), @migrations_folder)
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  def priv_path_for(repo) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split |> List.last |> Macro.underscore
    Path.join([priv_dir(app), repo_underscore])
  end
end
