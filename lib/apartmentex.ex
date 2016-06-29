defmodule Apartmentex do

  @schema_prefix Application.get_env(:apartmentex, :schema_prefix) || "tenant_"
  @tenant_migration_folder "priv/repo/tenant_migrations"
  #warning: don't change this after you already have tenants


  alias Ecto.Repo.Queryable
  alias Ecto.Repo.Model
  alias Ecto.Changeset
  alias Apartmentex.Helpers.Queryable, as: QHelpers
  alias Apartmentex.Helpers.Model, as: MHelpers
  require Ecto.Query

  def new_tenant(repo, tenant) do
    prefix = build_prefix(tenant)
    case repo.__adapter__ do
      Ecto.Adapters.Postgres -> Ecto.Adapters.SQL.query(repo, "CREATE SCHEMA #{prefix}", [])
      Ecto.Adapters.MySQL -> Ecto.Adapters.SQL.query(repo, "CREATE DATABASE #{prefix}", [])
    end
    Apartmentex.Migrator.run(repo, @tenant_migration_folder, :up, [all: true, prefix: String.to_atom(prefix)])
  end

  def drop_tenant(repo, tenant) do
    prefix = build_prefix(tenant)
    case repo.__adapter__ do
      Ecto.Adapters.Postgres -> Ecto.Adapters.SQL.query(repo, "DROP SCHEMA #{prefix} CASCADE", [])
      Ecto.Adapters.MySQL -> Ecto.Adapters.SQL.query(repo, "DROP DATABASE #{prefix}", [])
    end
  end

  def all(repo, queryable, tenant, opts \\ []) when is_list(opts) do
    query = queryable
    |> Ecto.Queryable.to_query()
    |> Map.put(:prefix, build_prefix(tenant))

    Queryable.execute(:all, repo, repo.__adapter__, query, opts) |> elem(1)
  end

  @doc """
  Implementation for `Apartmentex.get/5`
  """
  def get(repo, queryable, id, tenant, opts \\ []) do
    query = queryable
    |> Ecto.Queryable.to_query()
    |> Map.put(:prefix, build_prefix(tenant))

    one(repo, QHelpers.query_for_get(repo, query, id), tenant, opts)
  end

  @doc """
  Implementation for `Apartmentex.get!/5`
  """
  def get!(repo, queryable, id, tenant, opts \\ []) do

    one!(repo, QHelpers.query_for_get(repo, queryable, id), tenant, opts)
  end

  def get_by(repo, queryable, clauses, tenant, opts \\ []) do

    one(repo, QHelpers.query_for_get_by(repo, queryable, clauses), tenant, opts)
  end

  def get_by!(repo, queryable, clauses, tenant, opts \\ []) do

    one!(repo, QHelpers.query_for_get_by(repo, queryable, clauses), tenant, opts)
  end

  @doc """
  Implementation for `Apartmentex.one/4`
  """
  def one(repo, queryable, tenant, opts \\ []) do
    case all(repo, queryable, tenant, opts) do
      [one] -> one
      []    -> nil
      other -> raise Ecto.MultipleResultsError, queryable: queryable, count: length(other)
    end
  end

  @doc """
  Implementation for `Apartmentex.one!/4`
  """
  def one!(repo, queryable, tenant, opts \\ []) do
    case all(repo, queryable, tenant, opts) do
      [one] -> one
      []    -> raise Ecto.NoResultsError, queryable: queryable
      other -> raise Ecto.MultipleResultsError, queryable: queryable, count: length(other)
    end
  end

  #model derived functions

   @doc """
  Implementation for `Apartmentex.insert!/4`.
  """
  def insert(repo, %Changeset{} = changeset, tenant, opts) when is_list(opts) do
    changeset = MHelpers.update_changeset(changeset, :changeset, :insert, repo, opts)

    new_changeset = %{changeset | model: Ecto.put_meta(changeset.model,  prefix: build_prefix(tenant))}
    MHelpers.do_insert(repo, repo.__adapter__, new_changeset, opts)
  end

  def insert(repo, %{__struct__: _} = struct, tenant, opts) when is_list(opts) do
    changeset =
      struct
      |> Ecto.Changeset.change()
      |> MHelpers.update_changeset(:model, :insert, repo, opts)

    new_changeset = %{changeset | model: Ecto.put_meta(changeset.model,  prefix: build_prefix(tenant))}
    MHelpers.do_insert(repo, repo.__adapter__, new_changeset, opts)
  end

  def insert(repo, model_or_changeset, tenant, opts \\ []) do
    insert(repo, model_or_changeset, tenant, opts)
  end

  def insert!(repo, model_or_changeset, tenant, opts \\ []) do
    case insert(repo, model_or_changeset, tenant, opts) do
      {:ok, model} -> model
      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
    end
  end





  @doc """
  Implementation for `Apartmentex.update!/4`.
  """
  def update(repo, %Changeset{} = changeset, tenant, opts) when is_list(opts) do
    changeset = MHelpers.update_changeset(changeset, :changeset, :update, repo, opts)

    new_changeset = %{changeset | model: Ecto.put_meta(changeset.model,  prefix: build_prefix(tenant))}
    MHelpers.do_update(repo, repo.__adapter__, new_changeset, opts)
  end

  def update(repo, %{__struct__: model} = struct, tenant, opts) when is_list(opts) do
    changes =
      struct
      |> Map.take(model.__schema__(:fields))
      |> Map.drop(model.__schema__(:primary_key))
      |> Map.drop(model.__schema__(:embeds))

    changeset =
      struct
      |> Ecto.Changeset.change()
      |> Map.put(:changes, changes)
      |> MHelpers.update_changeset(:model, :update, repo, opts)

    new_changeset = %{changeset | model: Ecto.put_meta(changeset.model,  prefix: build_prefix(tenant))}
    MHelpers.do_update(repo, repo.__adapter__, new_changeset, opts)
  end

  def update(repo, model_or_changeset, tenant, opts \\ []) do
    update(repo, model_or_changeset, tenant, opts)
  end

  def update!(repo, model_or_changeset, tenant, opts \\ []) do
    case update(repo, model_or_changeset, tenant, opts) do
      {:ok, model} -> model
      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :update, changeset: changeset
    end
  end



   @doc """
  Runtime callback for `Apartmentex.update_all/5`
  """
  def update_all(repo, queryable, [], tenant, opts) when is_list(opts) do
    update_all(repo, queryable, tenant, opts)
  end

  def update_all(repo, queryable, updates, tenant, opts) when is_list(opts) do

    query = Ecto.Query.from q in queryable, update: ^updates
    update_all(repo, query, tenant, opts)
  end

  defp update_all(repo, queryable, tenant, opts \\ []) do
    query = queryable
    |> Ecto.Queryable.to_query()
    |> Map.put(:prefix, build_prefix(tenant))

    Queryable.execute(:update_all, repo, repo.__adapter__, query, opts)
  end

  @doc """
  Implementation for `Apartmentex.delete!/4`.
  """
  def delete(repo, %Changeset{} = changeset, tenant, opts) when is_list(opts) do
    changeset = MHelpers.update_changeset(changeset, :changeset, :delete, repo, opts)

    new_changeset = %{changeset | model: Ecto.put_meta(changeset.model,  prefix: build_prefix(tenant))}
    MHelpers.do_delete(repo, repo.__adapter__, new_changeset, opts)
  end

  def delete(repo, %{__struct__: _} = struct, tenant, opts) when is_list(opts) do
    changeset =
      struct
      |> Ecto.Changeset.change()
      |> MHelpers.update_changeset(:model, :delete, repo, opts)

    new_changeset = %{changeset | model: Ecto.put_meta(changeset.model,  prefix: build_prefix(tenant))}
    MHelpers.do_delete(repo, repo.__adapter__, new_changeset, opts)
  end

  def delete(repo, model_or_changeset, tenant, opts \\ []) do
    delete(repo, model_or_changeset, tenant, opts)
  end

  def delete!(repo, model_or_changeset, tenant, opts \\ []) do
    case delete(repo, model_or_changeset, tenant, opts) do
      {:ok, model} -> model
      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :delete, changeset: changeset
    end
  end



  @doc """
  Implementation for `Apartmentex.delete_all/4`
  """
  def delete_all(repo, queryable, tenant, opts \\ []) do
    query = queryable
    |> Ecto.Queryable.to_query()
    |> Map.put(:prefix, build_prefix(tenant))

    Queryable.execute(:delete_all, repo, repo.__adapter__, query, opts)
  end

  #helpers

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
