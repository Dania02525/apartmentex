defmodule Apartmentex.TenantActions do
  import Apartmentex.MigrationsPathBuilder
  import Apartmentex.PrefixBuilder

  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.Postgres
  alias Ecto.Adapters.MySQL

  @doc """
  Apply migrations to a tenant with given strategy, in given direction.

  A direction can be given, as the third parameter, which defaults to `:up`
  A strategy can be given as an option, and defaults to `:all`

  ## Options

    * `:all` - runs all available if `true`
    * `:step` - runs the specific number of migrations
    * `:to` - runs all until the supplied version is reached
    * `:log` - the level to use for logging. Defaults to `:info`.
      Can be any of `Logger.level/0` values or `false`.

  """
  def migrate_tenant(repo, tenant, direction \\ :up, opts \\ []) do
    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :all, true)

    migrate_and_return_status(repo, tenant, direction, opts)
  end

  def new_tenant(repo, tenant) do
    create_schema(repo, tenant)
    migrate_tenant(repo, tenant)
  end

  def create_schema(repo, tenant) do
    prefix = build_prefix(tenant)
    case repo.__adapter__ do
      Postgres -> SQL.query(repo, "CREATE SCHEMA \"#{prefix}\"", [])
      MySQL    -> SQL.query(repo, "CREATE DATABASE #{prefix}", [])
      Mongo.Ecto -> nil
    end
  end

  def drop_tenant(repo, tenant) do
    prefix = build_prefix(tenant)
    case repo.__adapter__ do
      Postgres -> SQL.query(repo, "DROP SCHEMA \"#{prefix}\" CASCADE", [])
      MySQL    -> SQL.query(repo, "DROP DATABASE #{prefix}", [])
      Mongo.Ecto -> Mongo.Ecto.command(repo, [dropDatabase: 1], [database: prefix])
    end
  end

  defp migrate_and_return_status(repo, tenant, direction, opts) do
    prefix = build_prefix(tenant)

    {status, versions} = handle_database_exceptions fn ->
      opts_with_prefix = Keyword.put(opts, :prefix, prefix)
      Ecto.Migrator.run(
        repo,
        tenant_migrations_path(repo),
        direction,
        opts_with_prefix
      )
    end

    {status, prefix, versions}
  end

  defp handle_database_exceptions(fun) do
    try do
      {:ok, fun.()}
    rescue
      e in Postgrex.Error ->
        {:error, Postgrex.Error.message(e)}
      e in Mariaex.Error ->
        {:error, Mariaex.Error.message(e)}
    end
  end
end
