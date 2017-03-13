defmodule Mix.Tasks.Apartmentex.Dump.TemplateTest do
  use ExUnit.Case, async: false

  import Support.FileHelpers
  import Mix.Tasks.Apartmentex.Dump.Template, only: [run: 1]

  alias Apartmentex.TestPostgresRepo
  alias Apartmentex.TestMySqlRepo

  @output Path.join(tmp_path(), "apartmentex_templates")

  setup_all do
    File.rm_rf!(@output)
    :ok
  end

  test "it generates a dump file for postgres" do
    run ["-r", to_string(TestPostgresRepo), "-d", Path.join(@output, "pg.sql")]
    assert_file Path.join(@output, "pg.sql"), fn file ->
      assert file =~ "CREATE TABLE notes"
    end
  end

  test "it generates a dump file for mysql" do
    run ["-r", to_string(TestMySqlRepo), "-d", Path.join(@output, "mysql.sql")]
    assert_file Path.join(@output, "mysql.sql"), fn file ->
      assert file =~ "CREATE TABLE `notes`"
    end
  end
end
