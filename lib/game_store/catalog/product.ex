defmodule GameStore.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :title, :string
    field :sku, :string
    field :price_cents, :integer
    field :stock, :integer, default: 0

    timestamps()
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:title, :sku, :price_cents, :stock])
    |> validate_required([:title, :sku, :price_cents])
    |> validate_number(:price_cents, greater_than_or_equal_to: 0)
    |> validate_number(:stock, greater_than_or_equal_to: 0)
    |> unique_constraint(:sku)
  end
end

