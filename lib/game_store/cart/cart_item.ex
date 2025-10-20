defmodule GameStore.Cart.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :quantity, :integer, default: 1
    belongs_to :cart, GameStore.Cart.Cart
    belongs_to :product, GameStore.Catalog.Product
    timestamps()
  end

  def changeset(ci, attrs) do
    ci
    |> cast(attrs, [:quantity, :cart_id, :product_id])
    |> validate_required([:quantity, :cart_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
    |> unique_constraint([:cart_id, :product_id])
  end
end
