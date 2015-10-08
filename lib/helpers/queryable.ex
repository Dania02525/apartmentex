defmodule Apartmentex.Helpers.Queryable do

  require Ecto.Query

  def query_for_get(_repo, _queryable, nil) do
    raise ArgumentError, "cannot perform Apartmentex.get/5 because the given value is nil"
  end

  def query_for_get(_repo, queryable, id) do
    query = Ecto.Queryable.to_query(queryable)
    model = assert_model!(query)
    primary_key = primary_key_field!(model)
    Ecto.Query.from(x in query, where: field(x, ^primary_key) == ^id)
  end

  def query_for_get_by(_repo, queryable, clauses) do
    Enum.reduce(clauses, queryable, fn
      {field, nil}, _query ->
        raise ArgumentError, "cannot perform Apartmentex.get_by/5 because #{inspect field} is nil"
      {field, value}, query ->
        query |> Ecto.Query.where([x], field(x, ^field) == ^value)
    end)
  end 

  def assert_model!(query) do
    case query.from do
      {_source, model} when model != nil ->
        model
      _ ->
        raise Ecto.QueryError,
          query: query,
          message: "expected a from expression with a model"
    end
  end

  def primary_key_field!(model) when is_atom(model) do
    case model.__schema__(:primary_key) do
      [field] -> field
      _ -> raise Ecto.NoPrimaryKeyFieldError, model: model
    end
  end

end