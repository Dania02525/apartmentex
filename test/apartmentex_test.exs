defmodule Apartmentex.ApartmentexTest do
  use ExUnit.Case

  alias Apartmentex.Note
  alias Apartmentex.TestPostgresRepo
  import Apartmentex.RepoAdditions

  @tenant_id 2

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestPostgresRepo)
    Apartmentex.new_tenant(TestPostgresRepo, @tenant_id)
    :ok
  end

  test ".all/4 only returns the tenant's records" do
    other_tenant_id = 1
    Apartmentex.new_tenant(TestPostgresRepo, other_tenant_id)

    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    _other_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "bar"}, other_tenant_id)

    fetched_notes = Apartmentex.all(TestPostgresRepo, Note, @tenant_id)
    fetched_note = List.first(fetched_notes)

    assert length(fetched_notes) == 1
    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".delete/4 deletes a tenant's record by id" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    {:ok, _ } = Apartmentex.delete(TestPostgresRepo, inserted_note, @tenant_id)

    refute Apartmentex.get(TestPostgresRepo, Note, inserted_note.id, @tenant_id)
  end

  test ".delete!/4 deletes a tenant's record by id" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    Apartmentex.delete!(TestPostgresRepo, inserted_note, @tenant_id)

    refute Apartmentex.get(TestPostgresRepo, Note, inserted_note.id, @tenant_id)
  end

  test ".delete_all/4 updates multiple records" do
    Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    Apartmentex.insert!(TestPostgresRepo, %Note{body: "bar"}, @tenant_id)

    Apartmentex.delete_all(TestPostgresRepo, Note, @tenant_id)

    assert length(Apartmentex.all(TestPostgresRepo, Note, @tenant_id)) == 0
  end

  test ".get/5 returns a tenant's record by id" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    fetched_note = Apartmentex.get(TestPostgresRepo, Note, inserted_note.id, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".get!/5 returns a tenant's record by id" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    fetched_note = Apartmentex.get!(TestPostgresRepo, Note, inserted_note.id, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".get_by/5 returns a tenant's record by conditions" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    fetched_note = Apartmentex.get_by(TestPostgresRepo, Note, %{body: "foo"}, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".get_by!/5 returns a tenant's record by conditions" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    fetched_note = Apartmentex.get_by!(TestPostgresRepo, Note, %{body: "foo"}, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".insert/4 can insert a changeset" do
    changeset = Note.changeset(%Note{}, %{body: "foo"})
    {:ok, inserted_note} = Apartmentex.insert(TestPostgresRepo, changeset, @tenant_id)
    fetched_note = Apartmentex.get!(TestPostgresRepo, Note, inserted_note.id, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".insert/4 can insert a model" do
    {:ok, inserted_note} = Apartmentex.insert(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    fetched_note = Apartmentex.get!(TestPostgresRepo, Note, inserted_note.id, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".insert!/4 can insert a changeset" do
    changeset = Note.changeset(%Note{}, %{body: "foo"})
    inserted_note = Apartmentex.insert!(TestPostgresRepo, changeset, @tenant_id)
    fetched_note = Apartmentex.get!(TestPostgresRepo, Note, inserted_note.id, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".insert!/4 can insert a model" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    fetched_note = Apartmentex.get!(TestPostgresRepo, Note, inserted_note.id, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".one/4 returns a tenant's record" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    fetched_note = Apartmentex.one(TestPostgresRepo, Note, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".one!/4 returns a tenant's record" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    fetched_note = Apartmentex.one!(TestPostgresRepo, Note, @tenant_id)

    assert fetched_note.id == inserted_note.id
    assert fetched_note.body == "foo"
  end

  test ".update/4 updates a tenant's record" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    changeset = Note.changeset(inserted_note, %{body: "bar"})
    {:ok, updated_note} = Apartmentex.update(TestPostgresRepo, changeset, @tenant_id)

    assert updated_note.id == inserted_note.id
    assert updated_note.body == "bar"
  end

  test ".update!/4 updates a tenant's record" do
    inserted_note = Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    changeset = Note.changeset(inserted_note, %{body: "bar"})
    updated_note = Apartmentex.update!(TestPostgresRepo, changeset, @tenant_id)

    assert updated_note.id == inserted_note.id
    assert updated_note.body == "bar"
  end

  test ".update_all/4 updates multiple records" do
    Apartmentex.insert!(TestPostgresRepo, %Note{body: "foo"}, @tenant_id)
    Apartmentex.insert!(TestPostgresRepo, %Note{body: "bar"}, @tenant_id)

    Apartmentex.update_all(TestPostgresRepo, Note, [set: [body: "updated"]], @tenant_id)

    updated_notes = Apartmentex.all(TestPostgresRepo, Note, @tenant_id)
    assert Enum.map(updated_notes, & &1.body) == ["updated", "updated"]
  end

  test ".set_tenant/2 struct adds the tenant prefix" do
    prefix = %Note{}
    |> set_tenant(@tenant_id)
    |> Ecto.get_meta(:prefix)
    assert prefix == "tenant_2"
  end

  test ".set_tenant/2 changeset adds the tenant prefix" do
    prefix = Note.changeset(%Note{}, %{})
    |> set_tenant(@tenant_id)
    |> Map.fetch!(:data)
    |> Ecto.get_meta(:prefix)

    assert prefix == "tenant_2"
  end

  test ".set_tenant/2 queryable adds the tenant prefix" do
    prefix = Note
    |> set_tenant(@tenant_id)
    |> Map.fetch!(:prefix)

    assert prefix == "tenant_#{@tenant_id}"
  end
end
