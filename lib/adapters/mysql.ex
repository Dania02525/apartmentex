defmodule Apartmentex.Adapters.MySQL do
  @moduledoc """
  Adapter module for MySQL.

  """

  # Inherit all behaviour from Ecto.Adapters.SQL
  use Apartmentex.Adapters.SQL, :mariaex

  # And provide a custom storage implementation
  @behaviour Apartmentex.Adapter.Storage

  @doc false
  def supports_ddl_transaction? do
    false
  end
end
