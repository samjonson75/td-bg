defmodule TrueBG.Repo.Migrations.CreateMasterRoles do
  use Ecto.Migration

  alias TrueBG.Permissions
  alias TrueBG.Permissions.Role

  def change do
    Enum.each Role.get_roles, fn role_name ->
      role_name = Atom.to_string role_name
      Permissions.create_role(%{name: role_name})
    end
  end
end