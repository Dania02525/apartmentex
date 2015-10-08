defmodule Apartmentex.Adapters.SQL.Query do
  @moduledoc """
  Specifies the behaviour to be implemented by the
  connection for handling all SQL queries.
  """

  use Behaviour

  @type result :: {:ok, %{rows: nil | [tuple], num_rows: non_neg_integer}} |
                  {:error, Exception.t}

  ## DDL

  @doc """
  Receives a DDL command and returns a query that executes it.
  """
  defcallback execute_ddl(Ecto.Adapter.Migration.command) :: String.t

  ## Transaction

  @doc """
  Command to begin transaction.
  """
  defcallback begin_transaction :: String.t

  @doc """
  Command to rollback transaction.
  """
  defcallback rollback :: String.t

  @doc """
  Command to commit transaction.
  """
  defcallback commit :: String.t

  @doc """
  Command to emit savepoint.
  """
  defcallback savepoint(savepoint :: String.t) :: String.t

  @doc """
  Command to rollback to savepoint.
  """
  defcallback rollback_to_savepoint(savepoint :: String.t) :: String.t
end
