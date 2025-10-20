defmodule GameStore.Repo.Migrations.CreateCarts do
  use Ecto.Migration

  def change do
    create table(:carts) do
      add :token, :binary_id, null: false
      add :status, :string, default: "open", null: false
      timestamps()
    end

    create unique_index(:carts, [:token])
  end

end
