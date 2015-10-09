if Code.ensure_loaded?(Mariaex.Connection) do

  defmodule Apartmentex.Adapters.MySQL.Connection do
    @moduledoc false

    @default_port 3306
    @behaviour Apartmentex.Adapters.Connection
    @behaviour Apartmentex.Adapters.SQL.Query

    ## Connection

    def connect(opts) do
      opts = Keyword.update(opts, :port, @default_port, &normalize_port/1)
      Mariaex.Connection.start_link(opts)
    end

    def query(conn, sql, params, opts \\ []) do
      params = Enum.map params, fn
        %Ecto.Query.Tagged{value: value} -> value
        %{__struct__: _} = value -> value
        %{} = value -> json_library.encode!(value)
        value -> value
      end

      case Mariaex.Connection.query(conn, sql, params, opts) do
        {:ok, res}        -> {:ok, Map.from_struct(res)}
        {:error, _} = err -> err
      end
    end

    defp normalize_port(port) when is_binary(port), do: String.to_integer(port)
    defp normalize_port(port) when is_integer(port), do: port

    defp json_library do
      Application.get_env(:ecto, :json_library)
    end

    def to_constraints(%Mariaex.Error{mariadb: %{code: 1062, message: message}}) do
      case :binary.split(message, " for key ") do
        [_, quoted] -> [unique: strip_quotes(quoted)]
        _ -> []
      end
    end
    def to_constraints(%Mariaex.Error{mariadb: %{code: code, message: message}})
        when code in [1451, 1452] do
      case :binary.split(message, [" CONSTRAINT ", " FOREIGN KEY "], [:global]) do
        [_, quoted, _] -> [foreign_key: strip_quotes(quoted)]
        _ -> []
      end
    end
    def to_constraints(%Mariaex.Error{}),
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

    ## DDL

    alias Ecto.Migration.Table
    alias Ecto.Migration.Index
    alias Ecto.Migration.Reference

    def execute_ddl({command, %Table{} = table, columns}) when command in [:create, :create_if_not_exists] do
      engine  = engine_expr(table.engine)
      options = options_expr(table.options)
      if_not_exists = if command == :create_if_not_exists, do: " IF NOT EXISTS", else: ""

      "CREATE TABLE" <> if_not_exists <>
        " #{quote_table(table.prefix, table.name)} (#{column_definitions(table, columns)})" <> engine <> options
    end

    def execute_ddl({command, %Table{} = table}) when command in [:drop, :drop_if_exists] do
      if_exists = if command == :drop_if_exists, do: " IF EXISTS", else: ""

      "DROP TABLE" <> if_exists <> " #{quote_table(table.prefix, table.name)}"
    end

    def execute_ddl({:alter, %Table{}=table, changes}) do
      "ALTER TABLE #{quote_table(table.prefix, table.name)} #{column_changes(table, changes)}"
    end

    def execute_ddl({:create, %Index{}=index}) do
      create = "CREATE#{if index.unique, do: " UNIQUE"} INDEX"
      using  = if index.using, do: "USING #{index.using}", else: []

      assemble([create,
                quote_name(index.name),
                "ON",
                quote_table(index.prefix, index.table),
                "(#{Enum.map_join(index.columns, ", ", &index_expr/1)})",
                using,
                if_do(index.concurrently, "LOCK=NONE")])
    end

    def execute_ddl({:create_if_not_exists, %Index{}}),
      do: error!(nil, "MySQL adapter does not support create if not exists for index")

    def execute_ddl({:drop, %Index{}=index}) do
      assemble(["DROP INDEX",
                quote_name(index.name),
                "ON #{quote_table(index.prefix, index.table)}",
                if_do(index.concurrently, "LOCK=NONE")])
    end

    def execute_ddl({:drop_if_exists, %Index{}}),
      do: error!(nil, "MySQL adapter does not support drop if exists for index")

    def execute_ddl({:rename, %Table{}=current_table, %Table{}=new_table}) do
      "RENAME TABLE #{quote_table(current_table.prefix, current_table.name)} TO #{quote_table(new_table.prefix, new_table.name)}"
    end

    def execute_ddl({:rename, %Table{}=table, current_column, new_column}) do
      [
        "SELECT @column_type := COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '#{table.name}' AND COLUMN_NAME = '#{current_column}' LIMIT 1",
        "SET @rename_stmt = concat('ALTER TABLE #{quote_table(table.prefix, table.name)} CHANGE COLUMN `#{current_column}` `#{new_column}` ', @column_type)",
        "PREPARE rename_stmt FROM @rename_stmt",
        "EXECUTE rename_stmt"
      ]
    end

    def execute_ddl(string) when is_binary(string), do: string

    def execute_ddl(keyword) when is_list(keyword),
      do: error!(nil, "MySQL adapter does not support keyword lists in execute")

    defp column_definitions(table, columns) do
      Enum.map_join(columns, ", ", &column_definition(table, &1))
    end

    defp column_definition(table, {:add, name, %Reference{} = ref, opts}) do
      assemble([quote_name(name), reference_column_type(ref.type, opts),
                column_options(name, opts), reference_expr(ref, table, name)])
    end

    defp column_definition(_table, {:add, name, type, opts}) do
      assemble([quote_name(name), column_type(type, opts), column_options(name, opts)])
    end

    defp column_changes(table, columns) do
      Enum.map_join(columns, ", ", &column_change(table, &1))
    end

    defp column_change(table, {:add, name, %Reference{} = ref, opts}) do
      assemble(["ADD", quote_name(name), reference_column_type(ref.type, opts),
                column_options(name, opts), constraint_expr(ref, table, name)])
    end

    defp column_change(_table, {:add, name, type, opts}) do
      assemble(["ADD", quote_name(name), column_type(type, opts), column_options(name, opts)])
    end

    defp column_change(table, {:modify, name, %Reference{} = ref, opts}) do
      assemble([
        "MODIFY", quote_name(name), reference_column_type(ref.type, opts),
        column_options(name, opts), constraint_expr(ref, table, name)
      ])
    end

    defp column_change(_table, {:modify, name, type, opts}) do
      assemble(["MODIFY", quote_name(name), column_type(type, opts), column_options(name, opts)])
    end

    defp column_change(_table, {:remove, name}), do: "DROP #{quote_name(name)}"

    defp column_options(name, opts) do
      default = Keyword.fetch(opts, :default)
      null    = Keyword.get(opts, :null)
      pk      = Keyword.get(opts, :primary_key)

      [default_expr(default), null_expr(null), pk_expr(pk, name)]
    end

    defp pk_expr(true, name), do: ", PRIMARY KEY(#{quote_name(name)})"
    defp pk_expr(_, _), do: []

    defp null_expr(false), do: "NOT NULL"
    defp null_expr(true), do: "NULL"
    defp null_expr(_), do: []

    defp default_expr({:ok, nil}),
      do: "DEFAULT NULL"
    defp default_expr({:ok, literal}) when is_binary(literal),
      do: "DEFAULT '#{escape_string(literal)}'"
    defp default_expr({:ok, literal}) when is_number(literal) or is_boolean(literal),
      do: "DEFAULT #{literal}"
    defp default_expr({:ok, {:fragment, expr}}),
      do: "DEFAULT #{expr}"
    defp default_expr(:error),
      do: []

    defp index_expr(literal), do: quote_name(literal)

    defp engine_expr(nil),
      do: " ENGINE = INNODB"
    defp engine_expr(storage_engine),
      do: String.upcase(" ENGINE = #{storage_engine}")

    defp options_expr(nil),
      do: ""
    defp options_expr(keyword) when is_list(keyword),
      do: error!(nil, "MySQL adapter does not support keyword lists in :options")
    defp options_expr(options),
      do: " #{options}"

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

    defp constraint_expr(%Reference{} = ref, table, name),
      do: ", ADD CONSTRAINT #{reference_name(ref, table, name)} " <>
          "FOREIGN KEY (#{quote_name(name)}) " <>
          "REFERENCES #{quote_table(ref.prefix, ref.table)}(#{quote_name(ref.column)})" <>
          reference_on_delete(ref.on_delete)

    defp reference_expr(%Reference{} = ref, table, name),
      do: ", CONSTRAINT #{reference_name(ref, table, name)} FOREIGN KEY " <>
          "(#{quote_name(name)}) REFERENCES " <>
          "#{quote_table(ref.prefix, ref.table)}(#{quote_name(ref.column)})" <>
          reference_on_delete(ref.on_delete)

    defp reference_name(%Reference{name: nil}, table, column),
      do: quote_name("#{table.name}_#{column}_fkey")
    defp reference_name(%Reference{name: name}, _table, _column),
      do: quote_name(name)

    defp reference_column_type(:serial, _opts), do: "BIGINT UNSIGNED"
    defp reference_column_type(type, opts), do: column_type(type, opts)

    defp reference_on_delete(:nilify_all), do: " ON DELETE SET NULL"
    defp reference_on_delete(:delete_all), do: " ON DELETE CASCADE"
    defp reference_on_delete(_), do: ""

    ## Helpers

    defp quote_name(name)
    defp quote_name(name) when is_atom(name),
      do: quote_name(Atom.to_string(name))
    defp quote_name(name) do
      if String.contains?(name, "`") do
        error!(nil, "bad field name #{inspect name}")
      end

      <<?`, name::binary, ?`>>
    end

    defp quote_table(nil, name),    do: quote_table(name)
    defp quote_table(prefix, name), do: quote_table(prefix) <> "." <> quote_table(name)


    defp quote_table(name) when is_atom(name),
      do: quote_table(Atom.to_string(name))
    defp quote_table(name) do
      if String.contains?(name, "`") do
        error!(nil, "bad table name #{inspect name}")
      end
      <<?`, name::binary, ?`>>
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
      value
      |> :binary.replace("'", "''", [:global])
      |> :binary.replace("\\", "\\\\", [:global])
    end

    defp ecto_to_db(type, query \\ nil)
    defp ecto_to_db({:array, _}, query),
      do: error!(query, "Array type is not supported by MySQL")
    defp ecto_to_db(:id, _query),        do: "integer"
    defp ecto_to_db(:binary_id, _query), do: "binary(16)"
    defp ecto_to_db(:string, _query),    do: "varchar"
    defp ecto_to_db(:float, _query),     do: "double"
    defp ecto_to_db(:binary, _query),    do: "blob"
    defp ecto_to_db(:uuid, _query),      do: "binary(16)" # MySQL does not support uuid
    defp ecto_to_db(:map, _query),       do: "text"
    defp ecto_to_db(other, _query),      do: Atom.to_string(other)

    defp error!(nil, message) do
      raise ArgumentError, message
    end
    defp error!(query, message) do
      raise Ecto.QueryError, query: query, message: message
    end
  end
end
