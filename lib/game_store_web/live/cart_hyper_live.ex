defmodule GameStoreWeb.CartHyperLive do
  use GameStoreWeb, :live_view
  alias GameStore.Cart

  def mount(_params, session, socket) do
    token = session["cart_token"] || (t = Ecto.UUID.generate(); Cart.get_or_create_cart(t); t)
    cart = Cart.fetch_cart(token)
    {:ok, assign(socket, cart: cart, totals: Cart.cart_totals(cart), token: token)}
  end

	def handle_event("inc", %{"id" => id}, socket) do
	  iid = String.to_integer(id)
	  new_qty = find_qty(socket, id) + 1

	  case Cart.update_item(socket.assigns.token, iid, new_qty) do
	    {:ok, _} ->
	      {:noreply, refresh(socket)}

	    {:error, :insufficient_stock} ->
	      {:noreply, socket |> put_flash(:error, "Stock insuficiente") |> refresh()}

	    _ ->
	      {:noreply, socket}
	  end
	end


  def handle_event("dec", %{"id" => id}, socket) do
    q = find_qty(socket, id) - 1
    if q > 0, do: Cart.update_item(socket.assigns.token, String.to_integer(id), q)
    {:noreply, refresh(socket)}
  end

  def handle_event("del", %{"id" => id}, socket) do
    Cart.remove_item(socket.assigns.token, String.to_integer(id))
    {:noreply, refresh(socket)}
  end

  def handle_event("checkout", _params, socket) do
    case Cart.checkout(socket.assigns.token) do
      {:ok, _cart} ->
        {:noreply, socket |> put_flash(:info, "Carro cerrado") |> refresh()}
      {:error, :already_closed} ->
        {:noreply, socket |> put_flash(:info, "El carro ya estaba cerrado")}
      _ ->
        {:noreply, socket |> put_flash(:error, "No se pudo cerrar el carro")}
    end
  end

  defp refresh(socket) do
    cart = Cart.fetch_cart(socket.assigns.token)
    assign(socket, cart: cart, totals: Cart.cart_totals(cart))
  end

  defp find_qty(socket, id) do
    {iid, _} = Integer.parse(id)
    (socket.assigns.cart.items |> Enum.find(&(&1.id == iid))).quantity
  end
end
