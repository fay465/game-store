# priv/repo/seeds.exs

alias GameStore.{Repo}
alias GameStore.Catalog.Product
alias GameStore.Cart.CartItem
import Ecto.Query, only: [from: 2]

# Tu lista (sin BG3):
products = [
  {"Elden Ring",             "ER-001",     39900,  70, "https://images.igdb.com/igdb/image/upload/t_cover_big/co4jni.webp"},
  {"Stardew Valley",         "SV-002",      7500, 300, "https://images.igdb.com/igdb/image/upload/t_cover_big/coa93h.webp"},
  {"Hollow Knight Silksong", "HK-004",     14900,  50, "https://images.igdb.com/igdb/image/upload/t_cover_big/coaend.webp"},
  {"Red Dead Redemption 2",  "RDR2-005",   29900,  30, "https://images.igdb.com/igdb/image/upload/t_cover_big/co1q1f.webp"},
  {"Cyberpunk 2077",         "CP2077-006", 34900,  25, "https://images.igdb.com/igdb/image/upload/t_cover_big/coaam3.webp"},
  {"Sekiro",                 "SEK-007",    35900,  40, "https://images.igdb.com/igdb/image/upload/t_cover_big/co2a23.webp"},
  {"Grand Theft Auto VI",    "GTA6-008",  100000,  10, "https://images.igdb.com/igdb/image/upload/t_cover_big/co9rwo.webp"},
  {"Balatro",                "BAL-009",     9990,  80, "https://images.igdb.com/igdb/image/upload/t_cover_big/co9f4g.webp"}
]

allowed_skus = Enum.map(products, fn {_, sku, _, _, _} -> sku end)

Repo.transaction(fn ->
  # 1) IDs de productos que YA NO están en la lista
  ids_to_remove =
    Repo.all(
      from p in Product,
        where: p.sku not in ^allowed_skus,
        select: p.id
    )

  # 2) Borra cart_items de esos productos (sin JOIN)
  if ids_to_remove != [] do
    {del_items, _} =
      from(ci in CartItem, where: ci.product_id in ^ids_to_remove)
      |> Repo.delete_all()
    IO.puts("CartItems borrados: #{del_items}")

    # 3) Borra productos que ya no están en la lista
    {del_products, _} =
      from(p in Product, where: p.id in ^ids_to_remove)
      |> Repo.delete_all()
    IO.puts("Products borrados: #{del_products}")
  else
    IO.puts("Nada para borrar (catálogo ya sincronizado)")
  end

  # 4) Upsert de los productos actuales
  upserted =
    for {title, sku, price_cents, stock, image_url} <- products do
      attrs = %{title: title, sku: sku, price_cents: price_cents, stock: stock, image_url: image_url}

      %Product{}
      |> Product.changeset(attrs)
      |> Repo.insert!(
           on_conflict: {:replace, [:title, :price_cents, :stock, :image_url, :updated_at]},
           conflict_target: :sku
         )
    end

  IO.puts("Upserted: #{length(upserted)}")
end)
