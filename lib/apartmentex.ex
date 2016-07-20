defmodule Apartmentex do
  @schema_prefix Application.get_env(:apartmentex, :schema_prefix) || "tenant_"
  @tenant_migration_folder "priv/repo/tenant_migrations"
  #warning: don't change this after you already have tenants

  alias Ecto.Changeset

  def new_tenant(repo, tenant) do
    prefix = build_prefix(tenant)
    case repo.__adapter__ do
      Ecto.Adapters.Postgres -> Ecto.Adapters.SQL.query(repo, "CREATE SCHEMA #{prefix}", [])
      Ecto.Adapters.MySQL -> Ecto.Adapters.SQL.query(repo, "CREATE DATABASE #{prefix}", [])
    end
    Ecto.Migrator.run(repo, @tenant_migration_folder, :up, [all: true, prefix: String.to_atom(prefix)])
  end

  def drop_tenant(repo, tenant) do
    prefix = build_prefix(tenant)
    case repo.__adapter__ do
      Ecto.Adapters.Postgres -> Ecto.Adapters.SQL.query(repo, "DROP SCHEMA #{prefix} CASCADE", [])
      Ecto.Adapters.MySQL -> Ecto.Adapters.SQL.query(repo, "DROP DATABASE #{prefix}", [])
    end
  end

  def all(repo, queryable, tenant, opts \\ []) when is_list(opts) do
    queryable
    |> add_prefix_to_query(tenant)
    |> repo.all(opts)
  end

  @doc """
  Implementation for `Apartmentex.get/5`
  """
  def get(repo, queryable, id, tenant, opts \\ []) do
    queryable
    |> add_prefix_to_query(tenant)
    |> repo.get(id, opts)
  end

  @doc """
  Implementation for `Apartmentex.get!/5`
  """
  def get!(repo, queryable, id, tenant, opts \\ []) do
    queryable
    |> add_prefix_to_query(tenant)
    |> repo.get!(id, opts)
  end

  def get_by(repo, queryable, clauses, tenant, opts \\ []) do
    queryable
    |> add_prefix_to_query(tenant)
    |> repo.get_by(clauses, opts)
  end

  def get_by!(repo, queryable, clauses, tenant, opts \\ []) do
    queryable
    |> add_prefix_to_query(tenant)
    |> repo.get_by!(clauses, opts)
  end

  @doc """
  Implementation for `Apartmentex.one/4`
  """
  def one(repo, queryable, tenant, opts \\ []) do
    queryable
    |> add_prefix_to_query(tenant)
    |> repo.one(opts)
  end

  @doc """
  Implementation for `Apartmentex.one!/4`
  """
  def one!(repo, queryable, tenant, opts \\ []) do
    queryable
    |> add_prefix_to_query(tenant)
    |> repo.one!(opts)
  end

  #model derived functions

   @doc """
  Implementation for `Apartmentex.insert/4`.
  """
  def insert(repo, model_or_changeset, tenant, opts \\ []) do
    model_or_changeset
    |> add_prefix(tenant)
    |> repo.insert(opts)
  end

  def insert!(repo, model_or_changeset, tenant, opts \\ []) do
    model_or_changeset
    |> add_prefix(tenant)
    |> repo.insert!(opts)
  end

  @doc """
  Implementation for `Apartmentex.update!/4`.
  """
  def update(repo, model_or_changeset, tenant, opts \\ []) do
    model_or_changeset
    |> add_prefix(tenant)
    |> repo.update(opts)
  end

  def update!(repo, model_or_changeset, tenant, opts \\ []) do
    model_or_changeset
    |> add_prefix(tenant)
    |> repo.update!(opts)
  end

   @doc """
  Runtime callback for `Apartmentex.update_all/5`
  """
  def update_all(repo, queryable, updates, tenant, opts \\ []) do
    queryable
    |> add_prefix_to_query(tenant)
    |> repo.update_all(updates, opts)
  end

  @doc """
  Implementation for `Apartmentex.delete/4`.
  """
  def delete(repo, model_or_changeset, tenant, opts \\ []) do
    model_or_changeset
    |> add_prefix(tenant)
    |> repo.delete(opts)
  end

  @doc """
  Implementation for `Apartmentex.delete!/4`.
  """
  def delete!(repo, model_or_changeset, tenant, opts \\ []) do
    model_or_changeset
    |> add_prefix(tenant)
    |> repo.delete!(opts)
  end

  @doc """
  Implementation for `Apartmentex.delete_all/4`
  """
  def delete_all(repo, queryable, tenant, opts \\ []) do
    queryable
    |> add_prefix_to_query(tenant)
    |> repo.delete_all(opts)
  end

  #helpers

  defp add_prefix(%Changeset{} = changeset, tenant) do
    %{changeset | data: add_prefix(changeset.data, tenant)}
  end

  defp add_prefix(%{__struct__: _} = model, tenant) do
    Ecto.put_meta(model,  prefix: build_prefix(tenant))
  end

  defp add_prefix_to_query(queryable, tenant) do
    queryable
    |> Ecto.Queryable.to_query
    |> Map.put(:prefix, build_prefix(tenant))
  end

  defp build_prefix(tenant) when is_integer(tenant) do
    @schema_prefix <> Integer.to_string(tenant)
  end

  defp build_prefix(tenant) when is_binary(tenant) do
    @schema_prefix <> tenant
  end

  defp build_prefix(tenant) do
    @schema_prefix <> Integer.to_string(tenant.id)
  end
end
