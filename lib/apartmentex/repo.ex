defmodule Apartmentex.Repo do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Ecto.Repo
      alias Apartmentex.TenantMissingError

      @repo Keyword.fetch!(opts, :repo)
      @untenanted [Ecto.Migration.SchemaMigration] ++ Keyword.get(opts, :untenanted, [])

      # From Ecto.Repo
      defdelegate __adapter__, to: @repo
      defdelegate __log__(entry), to: @repo
      defdelegate config(), to: @repo
      defdelegate start_link(opts \\ []), to: @repo
      defdelegate stop(pid, timeout \\ 5000), to: @repo
      defdelegate transaction(fun_or_multi, opts \\ []), to: @repo
      defdelegate in_transaction?(), to: @repo
      defdelegate rollback(value), to: @repo
      defdelegate aggregate(queryable, aggregate, field, opts \\ []), to: @repo
      defdelegate preload(struct_or_structs, preloads, opts \\ []), to: @repo

      # From Ecto.Adapters.SQL
      defdelegate __pool__, to: @repo
      defdelegate __sql__, to: @repo

      def all(queryable, opts \\ []) do
        assert_tenant(queryable)
        @repo.all(queryable, opts)
      end

      def get(queryable, id, opts \\ []) do
        assert_tenant(queryable)
        @repo.get(queryable, id, opts)
      end

      def get!(queryable, id, opts \\ []) do
        assert_tenant(queryable)
        @repo.get!(queryable, id, opts)
      end

      def get_by(queryable, clauses, opts \\ []) do
        assert_tenant(queryable)
        @repo.get_by(queryable, clauses, opts)
      end

      def get_by!(queryable, clauses, opts \\ []) do
        assert_tenant(queryable)
        @repo.get_by!(queryable, clauses, opts)
      end

      def one(queryable, opts \\ []) do
        assert_tenant(queryable)
        @repo.one(queryable, opts)
      end

      def one!(queryable, opts \\ []) do
        assert_tenant(queryable)
        @repo.one!(queryable, opts)
      end

      @insert_all_error """
      For insert_all
        - For tenanted tables
            - Your first parameter must be a tuple with the prefix, and the table name
        - For non-tenanted tables
            - Your first parameter may not be the string name of the table, because we can't
              check the associated model to see if it requires a tenant.
      """
      def insert_all(schema_or_source, entries, opts \\ [])
      def insert_all({nil, source} = schema_or_source, entries, opts) do
        if requires_tenant?(source) do
          raise TenantMissingError, message: @insert_all_error
        end
        @repo.insert_all(schema_or_source, entries, opts)
      end

      def insert_all({_prefix, _source} = schema_or_source, entries, opts), do: @repo.insert_all(schema_or_source, entries, opts)
      def insert_all(schema_or_source, entries, opts) when is_binary(schema_or_source), do: raise TenantMissingError, message: @insert_all_error
      def insert_all(schema_or_source, entries, opts) when is_atom(schema_or_source) do
        if requires_tenant?(schema_or_source) do
          raise TenantMissingError, message: @insert_all_error
        end
        @repo.insert_all(schema_or_source, entries, opts)
      end

      def insert_all(schema_or_source, entries, opts) do
        if requires_tenant?(schema_or_source) do
          raise TenantMissingError, message: @insert_all_error
        end
        @repo.insert_all(schema_or_source, entries, opts)
      end

      def update_all(queryable, updates, opts \\ []) do
        assert_tenant(queryable)
        @repo.update_all(queryable, updates, opts)
      end

      def delete_all(queryable, opts \\ []) do
        assert_tenant(queryable)
        @repo.delete_all(queryable, opts)
      end

      def insert(struct, opts \\ []) do
        assert_tenant(struct)
        @repo.insert(struct, opts)
      end

      def update(struct, opts \\ []) do
        assert_tenant(struct)
        @repo.update(struct, opts)
      end

      def insert_or_update(changeset, opts \\ []) do
        assert_tenant(changeset)
        @repo.insert_or_update(changeset, opts)
      end

      def delete(struct, opts \\ []) do
        assert_tenant(struct)
        @repo.delete(struct, opts)
      end

      def insert!(struct, opts \\ []) do
        assert_tenant(struct)
        @repo.insert!(struct, opts)
      end

      def update!(struct, opts \\ []) do
        assert_tenant(struct)
        @repo.update!(struct, opts)
      end

      def insert_or_update!(changeset, opts \\ []) do
        assert_tenant(changeset)
        @repo.insert_or_update!(changeset, opts)
      end

      def delete!(struct, opts \\ []) do
        assert_tenant(struct)
        @repo.delete!(struct, opts)
      end

      defp assert_tenant(%Ecto.Changeset{} = changeset) do
        assert_tenant(changeset.data)
      end

      defp assert_tenant(%{__meta__: _} = model) do
        if requires_tenant?(model) && !has_prefix?(model) do
          raise TenantMissingError, message: "No tenant specified in #{model.__struct__}"
        end
      end

      defp assert_tenant(queryable) do
        query = Ecto.Queryable.to_query(queryable)
        if requires_tenant?(query) && !has_prefix?(query) do
          raise TenantMissingError, message: "No tenant specified in #{get_model_from_query(query)}"
        end
      end

      defp has_prefix?(%{__meta__: _} = model) do
        if Ecto.get_meta(model, :prefix), do: true, else: false
      end


      defp get_model_from_query(%{from: {_, model}}), do: model

      defp requires_tenant?(%{from: {_, model}}), do: not model in @untenanted
      defp requires_tenant?(%{__struct__: model}), do: not model in @untenanted
      defp requires_tenant?(model), do: not model in @untenanted

      defp has_prefix?(%{prefix: nil}), do: false
      defp has_prefix?(%{prefix: _}), do: true
    end
  end
end
