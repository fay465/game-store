defmodule GameStore.Repo do
  use Ecto.Repo,
    otp_app: :game_store,
    adapter: Ecto.Adapters.SQLite3
end
