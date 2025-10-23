defmodule GameStoreWeb.ProductHelpers do
  alias GameStore.Catalog.Product

  def product_image(%Product{image_url: url}) when is_binary(url) and byte_size(url) > 0, do: url
  def product_image(_), do: "/images/placeholder-game.jpg"
end
