defmodule GameStore.Repo.Migrations.CreateCartItems do
  use Ecto.Migration

  def change do
    create table(:cart_items) do
      add :quantity, :integer, default: 1, null: false
      add :cart_id, references(:carts, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :restrict), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:cart_items, [:cart_id])
    create unique_index(:cart_items, [:cart_id, :product_id])
  end
end
