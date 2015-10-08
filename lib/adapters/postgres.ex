defmodule Apartmentex.Adapters.Postgres do
  @moduledoc """
  Adapter module for PostgreSQL.
  """

  # Inherit all behaviour from Ecto.Adapters.SQL
  use Apartmentex.Adapters.SQL, :postgrex

  # And provide a custom storage implementation
  @behaviour Apartmentex.Adapter.Storage

  @doc false

  def supports_ddl_transaction? do
    true
  end
end
