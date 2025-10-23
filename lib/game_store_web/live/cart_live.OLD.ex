defmodule GameStoreWeb.CartLive do
  use GameStoreWeb, :live_view
  alias GameStore.Cart

  def mount(_params, session, socket) do
    token = session["cart_token"]
    cart = Cart.fetch_cart(token)
    {:ok, assign(socket, cart: cart, totals: Cart.cart_totals(cart), token: token)}
  end

  def handle_event("inc", %{"id" => id}, socket) do
    Cart.update_item(socket.assigns.token, String.to_integer(id), 1 + find_qty(socket, id))
    {:noreply, refresh(socket)}
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

  defp refresh(socket) do
    cart = Cart.fetch_cart(socket.assigns.token)
    assign(socket, cart: cart, totals: Cart.cart_totals(cart))
  end

  defp find_qty(socket, id) do
    {iid, _} = Integer.parse(id)
    (socket.assigns.cart.items |> Enum.find(&(&1.id == iid))).quantity
  end
end
