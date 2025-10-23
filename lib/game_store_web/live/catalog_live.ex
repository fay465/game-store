defmodule GameStoreWeb.CatalogLive do
  use GameStoreWeb, :live_view
  alias GameStore.{Cart, Catalog}

  def mount(_params, session, socket) do
    # Asegura token de carro en sesión (igual que en el carrito)
    token =
      session["cart_token"] ||
        (t = Ecto.UUID.generate(); Cart.get_or_create_cart(t); t)

    products = Catalog.list_products()
    {:ok, assign(socket, products: products, token: token)}
  end

  def handle_event("add", %{"id" => id}, socket) do
    {pid, _} = Integer.parse(id)
    case Cart.add_item(socket.assigns.token, pid, 1) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Agregado al carro")}
      {:error, :insufficient_stock} ->
        {:noreply, socket |> put_flash(:error, "Stock insuficiente")}
      _ ->
        {:noreply, socket |> put_flash(:error, "No se pudo agregar")}
    end
  end
end
