defmodule GameStore.Cart do
  import Ecto.Query, only: [from: 2]
  alias GameStore.Repo

  # 👇 Alias a los ESQUEMAS (no al contexto)
  alias GameStore.Cart.{Cart, CartItem}
  alias GameStore.Catalog.Product

  # Crear u obtener carrito por token
  def get_or_create_cart(token) do
    case Repo.get_by(Cart, token: token) do
      nil ->
        %Cart{} |> Cart.changeset(%{token: token}) |> Repo.insert!()

      cart ->
        cart
    end
  end

  # Traer carrito con items y productos
  def fetch_cart(token) do
    Repo.one(
      from c in Cart,
        where: c.token == ^token,
        preload: [items: [:product]]
    )
  end

  # Totales del carrito
  def cart_totals(%Cart{} = cart) do
    items = Repo.preload(cart, items: [:product]).items

    subtotal =
      Enum.reduce(items, 0, fn it, acc ->
        acc + it.quantity * it.product.price_cents
      end)

    %{items: items, subtotal_cents: subtotal}
  end

  # Agregar item (suma si ya existe)

  def add_item(token, product_id, qty) when qty > 0 do
    cart = get_or_create_cart(token)
    product = Repo.get!(Product, product_id)

    case Repo.get_by(CartItem, cart_id: cart.id, product_id: product.id) do
      nil ->
        if qty > product.stock do
          {:error, :insufficient_stock}
        else
          %CartItem{}
          |> CartItem.changeset(%{cart_id: cart.id, product_id: product.id, quantity: qty})
          |> Repo.insert()
        end

      ci ->
        new_qty = ci.quantity + qty
        if new_qty > product.stock do
          {:error, :insufficient_stock}
        else
          ci |> CartItem.changeset(%{quantity: new_qty}) |> Repo.update()
        end
    end
  end

  # Actualizar cantidad de un item
  def update_item(token, item_id, qty) when qty > 0 do
    with %Cart{} = cart <- Repo.get_by(Cart, token: token),
         %CartItem{} = ci <- Repo.get(CartItem, item_id),
         true <- ci.cart_id == cart.id,
         %Product{} = p <- Repo.get(Product, ci.product_id) do
      if qty > p.stock do
        {:error, :insufficient_stock}
      else
        ci |> CartItem.changeset(%{quantity: qty}) |> Repo.update()
      end
    else
      _ -> {:error, :not_found}
    end
  end

  # Eliminar item
  def remove_item(token, item_id) do
    with %Cart{} = cart <- Repo.get_by(Cart, token: token),
         %CartItem{} = ci <- Repo.get(CartItem, item_id),
         true <- ci.cart_id == cart.id do
      Repo.delete(ci)
    else
      _ -> {:error, :not_found}
    end
  end

  # Vaciar carrito
  def clear_cart(token) do
    case Repo.get_by(Cart, token: token) do
      %Cart{} = cart ->
        Repo.delete_all(from i in CartItem, where: i.cart_id == ^cart.id)
        {:ok, cart}

      _ ->
        {:error, :not_found}
    end
  end

  # Checkout
	def checkout(token) do
	  case Repo.get_by(Cart, token: token) do
	    nil ->
	      {:error, :not_found}

	    %Cart{status: "closed"} ->
	      {:error, :already_closed}

	    %Cart{} = cart ->
	      Repo.transaction(fn ->
	        # 1) Descontar stock de cada item del carro
	        items =
	          from(i in CartItem, where: i.cart_id == ^cart.id)
	          |> Repo.all()

	        Enum.each(items, fn i ->
	          {updated, _} =
	            from(p in Product, where: p.id == ^i.product_id and p.stock >= ^i.quantity)
	            |> Repo.update_all(inc: [stock: -i.quantity])

	          if updated != 1 do
	            Repo.rollback({:insufficient_stock_on_checkout, i.product_id})
	          end
	        end)

	        # 2) Cerrar carro
	        {:ok, cart} =
	          cart
	          |> Cart.changeset(%{status: "closed"})
	          |> Repo.update()

	        cart
	      end)
	      |> case do
	        {:ok, cart} -> {:ok, cart}
	        {:error, :already_closed} -> {:error, :already_closed}
	        {:error, {:insufficient_stock_on_checkout, _pid}} -> {:error, :insufficient_stock}
	        {:error, _} -> {:error, :checkout_failed}
	      end
	  end
	end
end
