defmodule GameStore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :title, :string, null: false
      add :sku, :string, null: false
      add :price_cents, :integer, null: false
      add :stock, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:products, [:sku])
  end
end
