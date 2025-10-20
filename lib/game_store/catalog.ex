defmodule GameStore.Catalog do
  import Ecto.Query, warn: false
  alias GameStore.{Repo, Catalog.Product}


  def list_products, do: Repo.all(Product)
  def get_product!(id), do: Repo.get!(Product, id)
  def create_product(attrs), do: %Product{} |> Product.changeset(attrs) |> Repo.insert()
end
