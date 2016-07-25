defmodule Apartmentex.TenantActions do
  @tenant_migration_folder "priv/repo/tenant_migrations"
  #warning: don't change this after you already have tenants

  import Apartmentex.PrefixBuilder

  def new_tenant(repo, tenant) do
    prefix = build_prefix(tenant)
    case repo.__adapter__ do
      Ecto.Adapters.Postgres -> Ecto.Adapters.SQL.query(repo, "CREATE SCHEMA #{prefix}", [])
      Ecto.Adapters.MySQL -> Ecto.Adapters.SQL.query(repo, "CREATE DATABASE #{prefix}", [])
    end
    Ecto.Migrator.run(repo, tenant_migration_folder(repo), :up, [all: true, prefix: String.to_atom(prefix)])
  end

  def drop_tenant(repo, tenant) do
    prefix = build_prefix(tenant)
    case repo.__adapter__ do
      Ecto.Adapters.Postgres -> Ecto.Adapters.SQL.query(repo, "DROP SCHEMA #{prefix} CASCADE", [])
      Ecto.Adapters.MySQL -> Ecto.Adapters.SQL.query(repo, "DROP DATABASE #{prefix}", [])
    end
  end

  defp tenant_migration_folder(repo) do
    Keyword.fetch!(repo.config(), :otp_app)
    |> Application.app_dir(@tenant_migration_folder)
  end
end
