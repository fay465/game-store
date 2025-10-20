defmodule GameStoreWeb.CartController do
  use GameStoreWeb, :controller
  alias GameStore.Cart

  def create(conn, _params) do
    token = Ecto.UUID.generate()
    Cart.get_or_create_cart(token)
    json(conn, %{token: token})
  end

  def show(conn, %{"token" => token}) do
    if cart = Cart.fetch_cart(token) do
      totals = Cart.cart_totals(cart)
      json(conn, serialize_cart(cart, totals))
    else
      conn |> put_status(:not_found) |> json(%{error: "cart_not_found"})
    end
  end

  def clear(conn, %{"token" => token}) do
    case Cart.clear_cart(token) do
      {:ok, _} -> json(conn, %{ok: true})
      _ -> conn |> put_status(:not_found) |> json(%{error: "cart_not_found"})
    end
  end

  def add_item(conn, %{"token" => token, "product_id" => pid, "quantity" => qty}) do
    with {product_id, ""} <- Integer.parse(to_string(pid)),
         {quantity, ""} <- Integer.parse(to_string(qty)) do
      case Cart.add_item(token, product_id, quantity) do
        {:ok, _ci} ->
          cart = Cart.fetch_cart(token)
          totals = Cart.cart_totals(cart)
          json(conn, serialize_cart(cart, totals))

        {:error, :insufficient_stock} ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: "insufficient_stock"})

        _ ->
          conn |> put_status(:bad_request) |> json(%{error: "invalid_params"})
      end
    else
      _ -> conn |> put_status(:bad_request) |> json(%{error: "invalid_params"})
    end
  end

  def update_item(conn, %{"token" => token, "id" => id, "quantity" => qty}) do
    with {item_id, ""} <- Integer.parse(to_string(id)),
         {quantity, ""} <- Integer.parse(to_string(qty)) do
      case Cart.update_item(token, item_id, quantity) do
        {:ok, _} ->
          cart = Cart.fetch_cart(token)
          totals = Cart.cart_totals(cart)
          json(conn, serialize_cart(cart, totals))

        {:error, :insufficient_stock} ->
          conn |> put_status(:unprocessable_entity) |> json(%{error: "insufficient_stock"})

        _ ->
          conn |> put_status(:bad_request) |> json(%{error: "invalid_params"})
      end
    else
      _ -> conn |> put_status(:bad_request) |> json(%{error: "invalid_params"})
    end
  end

  def remove_item(conn, %{"token" => token, "id" => id}) do
    with {item_id, ""} <- Integer.parse(to_string(id)),
         {:ok, _} <- Cart.remove_item(token, item_id),
         cart when not is_nil(cart) <- Cart.fetch_cart(token) do
      totals = Cart.cart_totals(cart)
      json(conn, serialize_cart(cart, totals))
    else
      _ -> conn |> put_status(:bad_request) |> json(%{error: "invalid_params"})
    end
  end

  defp serialize_cart(cart, totals) do
    %{
      token: cart.token,
      status: cart.status,
      items: Enum.map(totals.items, fn it ->
        %{
          id: it.id,
          product_id: it.product_id,
          title: it.product.title,
          quantity: it.quantity,
          unit_cents: it.product.price_cents,
          line_cents: it.quantity * it.product.price_cents
        }
      end),
      subtotal_cents: totals.subtotal_cents
    }
  end

  def checkout(conn, %{"token" => token}) do
    case Cart.checkout(token) do
      {:ok, cart} ->
        totals = Cart.cart_totals(cart)
        json(conn, serialize_cart(cart, totals))
      {:error, :already_closed} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "already_closed"})
      _ ->
        conn |> put_status(:not_found) |> json(%{error: "cart_not_found"})
    end
  end
end
