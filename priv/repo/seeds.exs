# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     GameStore.Repo.insert!(%GameStore.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias GameStore.Catalog

[
  {"Elden Ring", "ER-001", 39900},
  {"Hades II", "HA-002", 24900},
  {"Baldur's Gate 3", "BG3-003", 49900}
]
|> Enum.each(fn {title, sku, price} ->
  Catalog.create_product(%{
    title: title,
    sku: sku,
    price_cents: price,
    stock: 100
  })
end)
