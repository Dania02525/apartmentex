# Apartmentex 

Query and Insert into postgres schemas created with names like "tenant_1".

### Setup

This isn't ready for use yet


### Use
Simply replace Repo calls with the Apartmentex call, passing it the tenant id or the tenent struct itself

```elixir

  widgets = Apartmentex.all(Repo, Widget, tenant_id)

  Apartmentex.insert(Repo, changeset, tenant_id)

  Apartmentex.update(Repo, changeset, tenant_id)

  Apartmentex.delete!(Repo, widget, tenant_id)

```

### To Do

*Add create schema and drop schema functions

*Add migration by hijacking Ecto.Migrator
