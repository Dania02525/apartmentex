if Code.ensure_loaded?(Postgrex.Connection) do

  defmodule Apartmentex.Adapters.Postgres.Connection do
    @moduledoc false

    @default_port 5432
    @behaviour Apartmentex.Adapters.Connection
    @behaviour Apartmentex.Adapters.SQL.Query

    ## Connection

    def connect(opts) do
      json = Application.get_env(:ecto, :json_library)
      extensions = [{Apartmentex.Adapters.Postgres.DateTime, []},
                    {Postgrex.Extensions.JSON, library: json}]

      opts =
        opts
        |> Keyword.update(:extensions, extensions, &(&1 ++ extensions))
        |> Keyword.update(:port, @default_port, &normalize_port/1)

      Postgrex.Connection.start_link(opts)
    end

    def query(conn, sql, params, opts) do
      params = Enum.map params, fn
        %Ecto.Query.Tagged{value: value} -> value
        value -> value
      end

      case Postgrex.Connection.query(conn, sql, params, opts) do
        {:ok, res}        -> {:ok, Map.from_struct(res)}
        {:error, _} = err -> err
      end
    end

    defp normalize_port(port) when is_binary(port), do: String.to_integer(port)
    defp normalize_port(port) when is_integer(port), do: port

    def to_constraints(%Postgrex.Error{postgres: %{code: :unique_violation, constraint: constraint}}),
      do: [unique: constraint]
    def to_constraints(%Postgrex.Error{postgres: %{code: :foreign_key_violation, constraint: constraint}}),
      do: [foreign_key: constraint]

    # Postgres 9.2 and earlier does not provide the constraint field
    def to_constraints(%Postgrex.Error{postgres: %{code: :unique_violation, message: message}}) do
      case :binary.split(message, " unique constraint ") do
        [_, quoted] -> [unique: strip_quotes(quoted)]
        _ -> []
      end
    end
    def to_constraints(%Postgrex.Error{postgres: %{code: :foreign_key_violation, message: message}}) do
      case :binary.split(message, " foreign key constraint ") do
        [_, quoted] -> [foreign_key: strip_quotes(quoted)]
        _ -> []
      end
    end

    def to_constraints(%Postgrex.Error{}),
      do: []

    defp strip_quotes(quoted) do
      size = byte_size(quoted) - 2
      <<_, unquoted::binary-size(size), _>> = quoted
      unquoted
    end

    ## Transaction

    def begin_transaction do
      "BEGIN"
    end

    def rollback do
      "ROLLBACK"
    end

    def commit do
      "COMMIT"
    end

    def savepoint(savepoint) do
      "SAVEPOINT " <> savepoint
    end

    def rollback_to_savepoint(savepoint) do
      "ROLLBACK TO SAVEPOINT " <> savepoint
    end

    # DDL

    alias Apartmentex.Migration.Table
    alias Apartmentex.Migration.Index
    alias Apartmentex.Migration.Reference

    @drops [:drop, :drop_if_exists]

    def execute_ddl({command, %Table{}=table, columns}) when command in [:create, :create_if_not_exists] do
      options       = options_expr(table.options)
      if_not_exists = if command == :create_if_not_exists, do: " IF NOT EXISTS", else: ""

      "CREATE TABLE" <> if_not_exists <>
        " #{quote_table(table.prefix, table.name)} (#{column_definitions(table, columns)})" <> options
    end

    def execute_ddl({command, %Table{}=table}) when command in @drops do
      if_exists = if command == :drop_if_exists, do: " IF EXISTS", else: ""

      "DROP TABLE" <> if_exists <> " #{quote_table(table.prefix, table.name)}"
    end

    def execute_ddl({:alter, %Table{}=table, changes}) do
      "ALTER TABLE #{quote_table(table.prefix, table.name)} #{column_changes(table, changes)}"
    end

    def execute_ddl({:create, %Index{}=index}) do
      fields = Enum.map_join(index.columns, ", ", &index_expr/1)

      assemble(["CREATE",
                if_do(index.unique, "UNIQUE"),
                "INDEX",
                if_do(index.concurrently, "CONCURRENTLY"),
                quote_name(index.name),
                "ON",
                quote_table(index.prefix, index.table),
                if_do(index.using, "USING #{index.using}"),
                "(#{fields})"])
    end

    def execute_ddl({:create_if_not_exists, %Index{}=index}) do
      assemble(["DO $$",
                "BEGIN",
                execute_ddl({:create, index}) <> ";",
                "EXCEPTION WHEN duplicate_table THEN END; $$;"])
    end

    def execute_ddl({command, %Index{}=index}) when command in @drops do
      if_exists = if command == :drop_if_exists, do: "IF EXISTS", else: []

      assemble(["DROP",
                "INDEX",
                if_do(index.concurrently, "CONCURRENTLY"),
                if_exists,
                quote_table(index.prefix, index.name)])
    end

    def execute_ddl({:rename, %Table{}=current_table, %Table{}=new_table}) do
      "ALTER TABLE #{quote_table(current_table.prefix, current_table.name)} RENAME TO #{quote_table(new_table.prefix, new_table.name)}"
    end

    def execute_ddl({:rename, %Table{}=table, current_column, new_column}) do
      "ALTER TABLE #{quote_table(table.prefix, table.name)} RENAME #{quote_name(current_column)} TO #{quote_name(new_column)}"
    end

    def execute_ddl(string) when is_binary(string), do: string

    def execute_ddl(keyword) when is_list(keyword),
      do: error!(nil, "PostgreSQL adapter does not support keyword lists in execute")

    defp column_definitions(table, columns) do
      Enum.map_join(columns, ", ", &column_definition(table, &1))
    end

    defp column_definition(table, {:add, name, %Reference{} = ref, opts}) do
      assemble([
        quote_name(name), reference_column_type(ref.type, opts),
        column_options(ref.type, opts), reference_expr(ref, table, name)
      ])
    end

    defp column_definition(_table, {:add, name, type, opts}) do
      assemble([quote_name(name), column_type(type, opts), column_options(type, opts)])
    end

    defp column_changes(table, columns) do
      Enum.map_join(columns, ", ", &column_change(table, &1))
    end

    defp column_change(table, {:add, name, %Reference{} = ref, opts}) do
      assemble([
        "ADD COLUMN", quote_name(name), reference_column_type(ref.type, opts),
        column_options(ref.type, opts), reference_expr(ref, table, name)
      ])
    end

    defp column_change(_table, {:add, name, type, opts}) do
      assemble(["ADD COLUMN", quote_name(name), column_type(type, opts), column_options(type, opts)])
    end

    defp column_change(table, {:modify, name, %Reference{} = ref, opts}) do
      assemble([
        "ALTER COLUMN", quote_name(name), "TYPE", reference_column_type(ref.type, opts),
        constraint_expr(ref, table, name), modify_null(name, opts), modify_default(name, ref.type, opts)
      ])
    end

    defp column_change(_table, {:modify, name, type, opts}) do
      assemble(["ALTER COLUMN", quote_name(name), "TYPE",
                column_type(type, opts), modify_null(name, opts), modify_default(name, type, opts)])
    end

    defp column_change(_table, {:remove, name}), do: "DROP COLUMN #{quote_name(name)}"

    defp modify_null(name, opts) do
      case Keyword.get(opts, :null) do
        true  -> ", ALTER COLUMN #{quote_name(name)} DROP NOT NULL"
        false -> ", ALTER COLUMN #{quote_name(name)} SET NOT NULL"
        nil   -> []
      end
    end

    defp modify_default(name, type, opts) do
      case Keyword.fetch(opts, :default) do
        {:ok, val} -> ", ALTER COLUMN #{quote_name(name)} SET #{default_expr({:ok, val}, type)}"
        :error -> []
      end
    end

    defp column_options(type, opts) do
      default = Keyword.fetch(opts, :default)
      null    = Keyword.get(opts, :null)
      pk      = Keyword.get(opts, :primary_key)

      [default_expr(default, type), null_expr(null), pk_expr(pk)]
    end

    defp pk_expr(true), do: "PRIMARY KEY"
    defp pk_expr(_), do: []

    defp null_expr(false), do: "NOT NULL"
    defp null_expr(true), do: "NULL"
    defp null_expr(_), do: []

    defp default_expr({:ok, nil}, _type),
      do: "DEFAULT NULL"
    defp default_expr({:ok, []}, type),
      do: "DEFAULT ARRAY[]::#{ecto_to_db(type)}"
    defp default_expr({:ok, literal}, _type) when is_binary(literal),
      do: "DEFAULT '#{escape_string(literal)}'"
    defp default_expr({:ok, literal}, _type) when is_number(literal) or is_boolean(literal),
      do: "DEFAULT #{literal}"
    defp default_expr({:ok, {:fragment, expr}}, _type),
      do: "DEFAULT #{expr}"
    defp default_expr({:ok, expr}, type),
      do: raise(ArgumentError, "unknown default `#{inspect expr}` for type `#{inspect type}`. " <>
                               ":default may be a string, number, boolean, empty list or a fragment(...)")
    defp default_expr(:error, _),
      do: []

    defp index_expr(literal) when is_binary(literal),
      do: literal
    defp index_expr(literal),
      do: quote_name(literal)

    defp options_expr(nil),
      do: ""
    defp options_expr(keyword) when is_list(keyword),
      do: error!(nil, "PostgreSQL adapter does not support keyword lists in :options")
    defp options_expr(options),
      do: " #{options}"

    defp column_type({:array, type}, opts),
      do: column_type(type, opts) <> "[]"
    defp column_type(type, opts) do
      size      = Keyword.get(opts, :size)
      precision = Keyword.get(opts, :precision)
      scale     = Keyword.get(opts, :scale)
      type_name = ecto_to_db(type)

      cond do
        size            -> "#{type_name}(#{size})"
        precision       -> "#{type_name}(#{precision},#{scale || 0})"
        type == :string -> "#{type_name}(255)"
        true            -> "#{type_name}"
      end
    end

    defp reference_expr(%Reference{} = ref, table, name),
      do: "CONSTRAINT #{reference_name(ref, table, name)} REFERENCES " <>
          "#{quote_table(ref.prefix, ref.table)}(#{quote_name(ref.column)})" <>
          reference_on_delete(ref.on_delete)

    defp constraint_expr(%Reference{} = ref, table, name),
      do: ", ADD CONSTRAINT #{reference_name(ref, table, name)} " <>
          "FOREIGN KEY (#{quote_name(name)}) " <>
          "REFERENCES #{quote_table(ref.prefix, ref.table)}(#{quote_name(ref.column)})" <>
          reference_on_delete(ref.on_delete)

    # A reference pointing to a serial column becomes integer in postgres
    defp reference_name(%Reference{name: nil}, table, column),
      do: quote_name("#{table.name}_#{column}_fkey")
    defp reference_name(%Reference{name: name}, _table, _column),
      do: quote_name(name)

    defp reference_column_type(:serial, _opts), do: "integer"
    defp reference_column_type(type, opts), do: column_type(type, opts)

    defp reference_on_delete(:nilify_all), do: " ON DELETE SET NULL"
    defp reference_on_delete(:delete_all), do: " ON DELETE CASCADE"
    defp reference_on_delete(_), do: ""

    ## Helpers

    defp quote_name(name)
    defp quote_name(name) when is_atom(name),
      do: quote_name(Atom.to_string(name))
    defp quote_name(name) do
      if String.contains?(name, "\"") do
        error!(nil, "bad field name #{inspect name}")
      end
      <<?", name::binary, ?">>
    end

    defp quote_table(nil, name),    do: quote_table(name)
    defp quote_table(prefix, name), do: quote_table(prefix) <> "." <> quote_table(name)

    defp quote_table(name) when is_atom(name),
      do: quote_table(Atom.to_string(name))
    defp quote_table(name) do
      if String.contains?(name, "\"") do
        error!(nil, "bad table name #{inspect name}")
      end
      <<?", name::binary, ?">>
    end

    defp assemble(list) do
      list
      |> List.flatten
      |> Enum.join(" ")
    end

    defp if_do(condition, value) do
      if condition, do: value, else: []
    end

    defp escape_string(value) when is_binary(value) do
      :binary.replace(value, "'", "''", [:global])
    end

    defp ecto_to_db({:array, t}), do: ecto_to_db(t) <> "[]"
    defp ecto_to_db(:id),         do: "integer"
    defp ecto_to_db(:binary_id),  do: "uuid"
    defp ecto_to_db(:string),     do: "varchar"
    defp ecto_to_db(:datetime),   do: "timestamp"
    defp ecto_to_db(:binary),     do: "bytea"
    defp ecto_to_db(:map),        do: "jsonb"
    defp ecto_to_db(other),       do: Atom.to_string(other)

    defp error!(nil, message) do
      raise ArgumentError, message
    end
    defp error!(query, message) do
      raise Ecto.QueryError, query: query, message: message
    end
  end
end
