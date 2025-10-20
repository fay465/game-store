defmodule GameStoreWeb.MoneyHelpers do
  # Trata price_cents como pesos sin decimales (CLP)
  def clp(cents) when is_integer(cents) do
    cents
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/.{3}(?=.)/, "\\0.")
    |> String.reverse()
    |> then(&"$" <> &1)
  end
end
