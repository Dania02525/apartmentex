defmodule Apartmentex.TenantActionsTest do
  use ExUnit.Case

  alias Apartmentex.Note
  alias Apartmentex.TestPostgresRepo

  @migration_version 20160711125401
  @tenant_id 2

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestPostgresRepo)
  end

  test ".migrate_tenant/2 migrates the tenant forward" do
    create_tenant_schema

    assert_creates_notes_table fn ->
      {status, prefix, versions} = Apartmentex.migrate_tenant(TestPostgresRepo, @tenant_id)
      assert status == :ok
      assert prefix == "tenant_#{@tenant_id}"
      assert versions == [@migration_version]
    end
  end

  test ".migrate_tenant/2 returns an error tuple when it fails" do
    create_and_migrate_tenant

    force_migration_failure fn(expected_postgres_error) ->
      {status, prefix, error_message} = Apartmentex.migrate_tenant(TestPostgresRepo, @tenant_id)
      assert status == :error
      assert prefix == "tenant_#{@tenant_id}"
      assert error_message == expected_postgres_error
    end
  end

  test ".rollback_tenant/3 reverts the specified migration" do
    create_and_migrate_tenant

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

  defp create_and_migrate_tenant do
    Apartmentex.new_tenant(TestPostgresRepo, @tenant_id)
  end

  defp create_tenant_schema do
    Apartmentex.TenantActions.create_schema(TestPostgresRepo, @tenant_id)
  end

  defp find_tenant_notes do
    Apartmentex.all(TestPostgresRepo, Note, @tenant_id)
  end

  defp force_migration_failure(migration_function) do
    TestPostgresRepo
    |> Ecto.Adapters.SQL.query("DELETE FROM \"tenant_#{@tenant_id}\".\"schema_migrations\"", [])

    migration_function.("ERROR (duplicate_table): relation \"notes\" already exists")
  end
end
