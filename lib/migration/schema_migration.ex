defmodule Apartmentex.Migration.SchemaMigration do
  # Define a schema that works with the schema_migrations table
  @moduledoc false
  use Ecto.Model
  import Ecto.Query, only: [from: 2]

  @primary_key false
  schema "schema_migrations" do
    field :version, :integer
    timestamps updated_at: false
  end

  @opts [timeout: :infinity, log: false]

  def ensure_schema_migrations_table!(repo, opts) do
    adapter = get_adapter(repo)
    create_migrations_table(adapter, repo, opts)
  end

  def migrated_versions(repo, opts) do
    repo.all from(p in __MODULE__, select: p.version) |> Map.put(:prefix, Keyword.get(opts, :prefix, nil)), @opts
  end

  def up(repo, version, opts) do
    repo.insert! %__MODULE__{version: version} |> put_meta(prefix: Keyword.get(opts, :prefix, nil)), @opts
  end

  def down(repo, version, opts) do
    repo.delete_all from(p in __MODULE__, where: p.version == ^version) |> Map.put(:prefix, Keyword.get(opts, :prefix, nil)), @opts
  end

  defp create_migrations_table(adapter, repo, opts) do
    # DDL queries do not log, so we do not need
    # to pass log: false here.
    adapter.execute_ddl(repo,
      {:create_if_not_exists, %Apartmentex.Migration.Table{name: :schema_migrations, prefix: Keyword.get(opts, :prefix, nil)}, [
        {:add, :version, :bigint, primary_key: true},
        {:add, :inserted_at, :datetime, []}]}, @opts)
  end

  defp get_adapter(repo) do
    case repo.__adapter__ do
      Ecto.Adapters.Postgres -> Apartmentex.Adapters.Postgres
      Ecto.Adapters.MySQL -> Apartmentex.Adapters.MySQL
    end
  end
end
