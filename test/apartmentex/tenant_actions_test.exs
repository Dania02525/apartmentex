defmodule Apartmentex.TenantActionsTest do
  use ExUnit.Case

  alias Apartmentex.Note
  alias Apartmentex.TestPostgresRepo

  @migration_version 20160711125401
  @tenant_id 2

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestPostgresRepo)
    Apartmentex.new_tenant(TestPostgresRepo, @tenant_id)
    :ok
  end

  test ".migrate_tenant/2 migrates the tenant forward" do
    Apartmentex.rollback_tenant(TestPostgresRepo, @tenant_id, @migration_version)

    assert_creates_notes_table fn ->
      Apartmentex.migrate_tenant(TestPostgresRepo, @tenant_id)
    end
  end

  test ".rollback_tenant/3 reverts the specified migration" do
    assert_drops_notes_table fn ->
      Apartmentex.rollback_tenant(TestPostgresRepo, @tenant_id, @migration_version)
    end
  end

  defp assert_creates_notes_table(fun) do
    assert_notes_table_is_dropped
    fun.()
    assert_notes_table_is_present
  end

  defp assert_drops_notes_table(fun) do
    assert_notes_table_is_present
    fun.()
    assert_notes_table_is_dropped
  end

  defp assert_notes_table_is_dropped do
    assert_raise Postgrex.Error, fn ->
      find_tenant_notes
    end
  end

  defp assert_notes_table_is_present do
    assert find_tenant_notes == []
  end

  defp find_tenant_notes do
    Apartmentex.all(TestPostgresRepo, Note, @tenant_id)
  end
end
