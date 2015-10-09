# Apartmentex 

Easy SaaS for Phoenix/Ecto.

*Tenant-qualified queries targeting postgres schemas or MySql databases
*Automatic migrations for tenant tables to schema for Postgres or
database for MySQL

See an example app at https://github.com/Dania02525/widget_saas

### Setup

*Add this to your mix.exs deps: {:apartmentex, git: "https://github.com/Dania02525/apartmentex.git"}
*Run mix deps.get && mix deps.compile


### Use
Place tenant only migrations in a new folder in priv/repo called 
"tenant_migrations".  These migrations should use Apartmentex.Migration, 
not Ecto.Migration.

You can now add a new tenant and automatically create a new schema for Postgres users
or a new database for MySQL users, and run the migrations in 
priv/repo/tenant_migrations for that schema or database. 

Table references and indexes in a migration will be applied to the same tenant prefix as the table within 
tenant_migrations. 

```elixir

Apartmentex.new_tenant(Repo, tenant) 

```

When deleting a tenant, you can also automatically drop thier 
associated schema or database (for MySQL).  

```elixir

Apartmentex.drop_tenant(Repo, tenant)

```

include the tenant struct or tenant id in Apartmentex calls
for queries, inserts, updates, and deletes.  

```elixir

  widgets = Apartmentex.all(Repo, Widget, tenant_id)

  Apartmentex.insert(Repo, changeset, tenant_id)

  Apartmentex.update(Repo, changeset, tenant)

  Apartmentex.delete!(Repo, widget, tenant)

```

### To Do

*mix task to migrate or rollback all tenant schemas/databases
*tests
