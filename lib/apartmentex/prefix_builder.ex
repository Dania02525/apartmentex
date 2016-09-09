defmodule Apartmentex.PrefixBuilder do
  @schema_prefix Application.get_env(:apartmentex, :schema_prefix) || "tenant_"

  def build_prefix(tenant) when is_integer(tenant) do
    @schema_prefix <> Integer.to_string(tenant)
  end

  def build_prefix(tenant) when is_binary(tenant) do
    @schema_prefix <> tenant
  end

  def build_prefix(tenant) do
    @schema_prefix <> Integer.to_string(tenant.id)
  end

  def extract_tenant(table_prefix) do
    String.replace_prefix(table_prefix, @schema_prefix, "")
  end
end
