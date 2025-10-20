defmodule GameStore.Cart.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  schema "carts" do
    field :token, Ecto.UUID
    field :status, :string, default: "open"
    has_many :items, GameStore.Cart.CartItem
    timestamps()
  end

  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:token, :status])
    |> validate_required([:token])
    |> unique_constraint(:token)
  end
end
