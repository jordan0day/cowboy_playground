defmodule CowboyPlayground.Repo.Migrations.AddSecureConnectionColumnToRoutesTable do
  use Ecto.Migration

  def up do
    """
    ALTER TABLE routes
    ADD COLUMN secure_connection boolean DEFAULT false
    """
  end

  def down do
    """
    ALTER TABLE routes
    DROP COLUMN secure_connection RESTRICT
    """
  end
end
