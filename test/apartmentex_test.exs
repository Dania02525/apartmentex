defmodule Apartmentex.ApartmentexTest do
  use ExUnit.Case

  alias Apartmentex.TestPostgresRepo

  defmodule Note do
    use Ecto.Schema
    import Ecto.Changeset

    schema "notes" do
      field :body, :string
    end

    def changeset(model, params \\ :empty) do
      model
      |> cast(params, ~w(body), [])
    end
  end

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(TestPostgresRepo)
    :ok
  end

  test ".all/4 only returns the tenant's records" do
    tenant_id = 2
    other_tenant_id = 1

    Apartmentex.new_tenant(TestPostgresRepo, tenant_id)
    Apartmentex.new_tenant(TestPostgresRepo, other_tenant_id)

    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, tenant_id)
    _other_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "bar"}, other_tenant_id)

    fetched_notes = Apartmentex.all(TestPostgresRepo, Note, tenant_id)
    fetched_note = List.first(fetched_notes)

    assert length(fetched_notes) == 1
    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".get!/5 returns a tenant's record by id" do
    tenant_id = 2

    Apartmentex.new_tenant(TestPostgresRepo, tenant_id)

    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, tenant_id)
    fetched_note = Apartmentex.get!(TestPostgresRepo, Note, inserted_note.id, tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".get_by!/5 returns a tenant's record by conditions" do
    tenant_id = 2

    Apartmentex.new_tenant(TestPostgresRepo, tenant_id)

    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, tenant_id)
    fetched_note = Apartmentex.get_by!(TestPostgresRepo, Note, %{body: "foo"}, tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".update!/4 updates a tenant's record" do
    tenant_id = 2

    Apartmentex.new_tenant(TestPostgresRepo, tenant_id)

    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, tenant_id)
    changeset = Note.changeset(inserted_note, %{body: "bar"})
    updated_note = Apartmentex.update!(TestPostgresRepo, changeset, tenant_id)

    assert updated_note.id == inserted_note.id
    assert updated_note.body == "bar"
  end

  test ".delete!/4 deletes a tenant's record by id" do
    tenant_id = 2

    Apartmentex.new_tenant(TestPostgresRepo, tenant_id)

    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, tenant_id)
    Apartmentex.delete!(TestPostgresRepo, inserted_note, tenant_id)

    refute Apartmentex.get(TestPostgresRepo, Note, inserted_note.id, tenant_id)
  end
end
