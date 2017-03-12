defmodule Mix.Tasks.Apartmentex.Dump.Template do
  use Mix.Task

  import Mix.Ecto
  import Apartmentex.TenantActions
  import Apartmentex.PrefixBuilder

  @default_subpath "apartmentex_template"

  def run(args) do
    no_umbrella!("apartmentex.dump.template")
    {opts, _, _} =
      OptionParser.parse args, switches: [dump_path: :string], aliases: [d: :dump_path]

    repo = parse_repo(args) |> List.first
    path = opts[:dump_path] || default_path(repo)
    config = Keyword.merge(repo.config, opts)

    new_tenant(repo, "template")

    dump_template(repo, path, config)

    drop_tenant(repo, "template")
  end

  defp dump_template(repo, path, config) do
    case repo.__adapter__ do
      Ecto.Adapters.Postgres -> pg_dump(path, config)
      Ecto.Adapters.MySQL -> mysql_dump(path, config)
    end
  end

  defp default_path(repo) do
    Path.join([source_repo_priv(repo), @default_subpath, "structure.sql"])
  end

  defp pg_dump(path, config) do
    config = Keyword.put(config, :pg, true)
             |> Keyword.put(:schema, build_prefix("template"))

    File.mkdir_p!(Path.dirname(path))
    {_output, 0} =
      run_with_cmd("pg_dump", config, ["--file", path,
                                       "--schema-only",
                                       "--no-acl", "--no-owner",
                                       config[:database]])
  end

  defp mysql_dump(path, config) do
    config = Keyword.put(config, :mysql, true)
    File.mkdir_p!(Path.dirname(path))

    {output, 0} =
      run_with_cmd("mysqldump", config, ["--no-data",
                                         "--routines",
                                         "--protocol=tcp",
                                         "--databases", build_prefix("template")])
    File.write!(path, output)
  end

  # this should be in a PR for Ecto to add schema specification to dump
  defp run_with_cmd(cmd, opts, opt_args) do
    unless System.find_executable(cmd) do
      raise "could not find executable `#{cmd}` in path, " <>
            "please guarantee it is available before running ecto commands"
    end

    env =
      if opts[:pg], do: [{"PGCONNECT_TIMEOUT", "10"}], else: []

    env =
      cond do
        opts[:pg] && opts[:password] ->
          [{"PGPASSWORD", opts[:password]}|env]
        opts[:mysql] && opts[:password] ->
          [{"MYSQL_PWD", opts[:password]}|env]
        true ->
          env
      end

    args =
      []
    args =
      cond do
        opts[:pg] && opts[:username] ->
          ["-U", opts[:username]|args]
        opts[:mysql] && opts[:username] ->
          ["--user", opts[:username]|args]
        true ->
          args
      end
    args =
      cond do
        opts[:mysql] ->
          port = opts[:port] || System.get_env("MYSQL_TCP_PORT") || "3306"
          ["--port", to_string(port)|args]
        opts[:pg] && opts[:port] ->
          ["-p", to_string(opts[:port])|args]
        true ->
          args
      end
    args =
      cond do
        opts[:pg] && opts[:schema] ->
          ["-n", opts[:schema]|args]
        true ->
          args
      end
    args =
      cond do
        opts[:mysql] ->
          ["--host", (opts[:hostname] || System.get_env("MYSQL_HOST") || "localhost")|args]
        opts[:pg] ->
          ["--host", (opts[:hostname] || System.get_env("PGHOST") || "localhost")|args]
      end

    args = args ++ opt_args
    System.cmd(cmd, args, env: env, stderr_to_stdout: true)
  end
end
