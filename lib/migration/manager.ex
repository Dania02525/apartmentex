defmodule Apartmentex.Migration.Manager do

  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: __MODULE__)
  end

  def put_migration(migrator, prefix) do
    Agent.update(__MODULE__,fn migrations -> Dict.put_new(migrations, migrator, {nil, prefix}) end)
  end

  def put_runner(migrator, runner) do
    Agent.update(__MODULE__,fn migrations -> 
      Dict.update!(migrations, migrator, fn({nil, prefix}) -> {runner, prefix} end)
    end)
  end

  def get_runner(migrator) do
    {runner, _prefix} = Agent.get(__MODULE__, fn migrations -> Dict.fetch!(migrations, migrator) end)
    runner
  end

  def get_prefix(migrator) do
    {_runner, prefix} = Agent.get(__MODULE__, fn migrations -> Dict.fetch!(migrations, migrator) end)
    prefix
  end

  def stop() do
    Agent.stop(__MODULE__)
  end 

end