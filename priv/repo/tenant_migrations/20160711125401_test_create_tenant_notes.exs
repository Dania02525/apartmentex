defmodule Apartmentex.TestPostgresRepo.Migrations.CreateTenantUser do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :body, :string
    end
  end
end
