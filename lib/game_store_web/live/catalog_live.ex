defmodule GameStoreWeb.CatalogLive do
  use GameStoreWeb, :live_view
  alias GameStore.{Catalog, Cart}

  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:products, Catalog.list_products())
     |> assign(:cart_token, session["cart_token"])}
  end

  def handle_event("add", %{"id" => id}, socket) do
    Cart.add_item(socket.assigns.cart_token, String.to_integer(id), 1)
    {:noreply, socket |> put_flash(:info, "Agregado al carro")}
  end
end
