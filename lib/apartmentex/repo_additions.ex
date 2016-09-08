defmodule Apartmentex.RepoAdditions do
  alias Ecto.Changeset
  import Apartmentex.PrefixBuilder

  def set_tenant(%Changeset{} = changeset, tenant) do
    %{changeset | data: set_tenant(changeset.data, tenant)}
  end

  def set_tenant(%{__meta__: _} = model, tenant) do
    Ecto.put_meta(model,  prefix: build_prefix(tenant))
  end

  def set_tenant(queryable, tenant) do
    queryable
    |> Ecto.Queryable.to_query
    |> Map.put(:prefix, build_prefix(tenant))
  end
end
