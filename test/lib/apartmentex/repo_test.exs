defmodule Apartmentex.Test.UntenantedRepo do
  use Apartmentex.Repo, repo: Ecto.TestRepo, untenanted: [Apartmentex.Note]
end

defmodule Apartmentex.Test.TenantedRepo do
  use Apartmentex.Repo, repo: Ecto.TestRepo
end

defmodule Apartmentex.ApartmentexTest do
  use ExUnit.Case
  import Apartmentex.PrefixBuilder
  alias Apartmentex.{Note,TenantMissingError}
  alias Apartmentex.Test.{TenantedRepo,UntenantedRepo}

  @tenant_id 2
  @error_message "No tenant specified in Elixir.Apartmentex.Note"

  def set_tenant(%Ecto.Changeset{} = changeset, tenant) do
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

  def scoped_note_query do
    Note
    |> Ecto.Queryable.to_query
    |> set_tenant(@tenant_id)
  end

  def scoped_note do
    %Note{id: 1, body: "body"} |> set_tenant(@tenant_id)
  end

  def scoped_changeset do
    Note.changeset(scoped_note, %{body: "body"})
  end

  test ".all/2 verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.all(Note, [])
    end
    assert TenantedRepo.all(scoped_note_query, []) == [1]
    assert UntenantedRepo.all(Note, []) == [1]
  end

  test ".get/2 verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.get(Note, 1)
    end

    assert TenantedRepo.get(scoped_note_query, 1) == 1
    assert UntenantedRepo.get(Note, 1) == 1
  end

  test ".get!/2 verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.get(Note, 1)
    end

    assert TenantedRepo.get(scoped_note_query, 1) == 1
    assert UntenantedRepo.get(Note, 1) == 1
  end

  test ".get_by(queryable, clauses, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.get_by(Note, body: "immaterial")
    end

    assert TenantedRepo.get_by(scoped_note_query, body: "immaterial") == 1
    assert UntenantedRepo.get_by(Note, body: "immaterial") == 1
  end

  test ".get_by!(queryable, clauses, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.get_by!(Note, body: "immaterial")
    end

    assert TenantedRepo.get_by!(scoped_note_query, body: "immaterial") == 1
    assert UntenantedRepo.get_by!(Note, body: "immaterial") == 1
  end

  test ".one(queryable, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.one(Note)
    end

    assert TenantedRepo.one(scoped_note_query) == 1
    assert UntenantedRepo.one(Note) == 1
  end

  test ".one!(queryable, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.one!(Note)
    end

    assert TenantedRepo.one!(scoped_note_query) == 1
    assert UntenantedRepo.one!(Note) == 1
  end

  test ".insert_all(schema_or_source, entries, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, ~r/For insert_all/, fn ->
      TenantedRepo.insert_all(Note, [%Note{body: "body0"}])
    end
    assert_raise TenantMissingError, ~r/For insert_all/, fn ->
      TenantedRepo.insert_all("notes", [%Note{body: "body0"}])
    end
    assert_raise TenantMissingError, ~r/For insert_all/, fn ->
      TenantedRepo.insert_all({nil, "notes"}, [%Note{body: "body0"}])
    end
    assert_raise TenantMissingError, ~r/For insert_all/, fn ->
      TenantedRepo.insert_all({nil, Note}, [%Note{body: "body0"}])
    end


    assert TenantedRepo.insert_all({@tenant_id, "notes"}, [%{body: "body"}]) == {1, nil}
    assert TenantedRepo.insert_all({@tenant_id, Note}, [%{body: "body"}]) == {1, nil}
    assert UntenantedRepo.insert_all(Note, [%{body: "body0"}]) == {1, nil}
  end

  test ".update_all(queryable, updates, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.update_all(Note, set: [body: "new"])
    end

    assert TenantedRepo.update_all(scoped_note_query, set: [body: "new"])
    assert UntenantedRepo.update_all(Note, set: [body: "new"]) == {1, nil}
  end

  test ".delete_all(queryable, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.delete_all(Note)
    end

    assert TenantedRepo.delete_all(scoped_note_query) == {1, nil}
    assert UntenantedRepo.delete_all(Note) == {1, nil}
  end

  test ".insert(struct, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.insert(Note.changeset(%Note{}, %{}))
    end
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.insert(%Note{})
    end

    assert {:ok, _} = TenantedRepo.insert(scoped_note)
    assert {:ok, _} = TenantedRepo.insert(Note.changeset(scoped_note, %{}))
    assert {:ok, _} = UntenantedRepo.insert(%Note{})
  end

  test ".update(struct, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.update(Note.changeset(%Note{id: 1}, %{body: "body"}))
    end

    assert TenantedRepo.update(scoped_changeset)
    assert UntenantedRepo.update(Note.changeset(%Note{id: 1}, %{body: "body"}))
  end

  test ".insert_or_update(changeset, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.insert_or_update(Note.changeset(%Note{id: 1}, %{body: "body"}))
    end

    assert {:ok, _} = TenantedRepo.insert_or_update(scoped_changeset)
    assert {:ok, _} = UntenantedRepo.insert_or_update(Note.changeset(%Note{id: 1}, %{body: "body"}))
  end

  test ".delete(struct, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.delete(%Note{id: 1})
    end
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.delete(Note.changeset(%Note{id: 1}, %{}))
    end

    assert {:ok, _} = TenantedRepo.delete(scoped_note)
    assert {:ok, _} = TenantedRepo.delete(scoped_changeset)
    assert {:ok, _} = UntenantedRepo.delete(%Note{id: 1})
  end

  test ".insert!(struct, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.insert!(Note.changeset(%Note{}, %{}))
    end
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.insert!(%Note{})
    end

    assert TenantedRepo.insert!(scoped_note)
    assert TenantedRepo.insert!(Note.changeset(scoped_note, %{}))
    assert UntenantedRepo.insert!(%Note{})
  end

  test ".update!(struct, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.update!(Note.changeset(%Note{id: 1}, %{body: "body"}))
    end

    assert TenantedRepo.update!(scoped_changeset)
    assert UntenantedRepo.update!(Note.changeset(%Note{id: 1}, %{body: "body"}))
  end

  test ".insert_or_update!(changeset, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.insert_or_update!(Note.changeset(%Note{id: 1}, %{body: "body"}))
    end

    assert TenantedRepo.insert_or_update!(scoped_changeset)
    assert UntenantedRepo.insert_or_update!(Note.changeset(%Note{id: 1}, %{body: "body"}))
  end

  test ".delete!(struct, opts \\ []) verifies tenant existence" do
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.delete!(%Note{id: 1})
    end
    assert_raise TenantMissingError, @error_message, fn ->
      TenantedRepo.delete!(Note.changeset(%Note{id: 1}, %{}))
    end

    assert TenantedRepo.delete!(scoped_note)
    assert TenantedRepo.delete!(scoped_changeset)
    assert UntenantedRepo.delete!(%Note{id: 1})
  end
end
