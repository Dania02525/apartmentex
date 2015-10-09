defmodule Apartmentex.Adapters.MySQL do
  @moduledoc """
  Adapter module for MySQL.

  """

  # Inherit all behaviour from Ecto.Adapters.SQL
  use Apartmentex.Adapters.SQL, :mariaex


  @doc false
  def supports_ddl_transaction? do
    false
  end
end
