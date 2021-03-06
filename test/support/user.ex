defmodule TdBgWeb.User do
  @moduledoc false

  alias TdBgWeb.ApiServices.MockTdAuthService

  def get_role_by_name(role_name) do
    # Use hash to map name to role id for tests
    id = hash_to_int(role_name)
    %{id: id, name: role_name}
  end

  defp hash_to_int(s) do
    s
    |> (&:crypto.hash(:sha, &1)).()
    |> :binary.bin_to_list()
    |> Enum.sum()
  end

  def is_admin_bool(is_admin) do
    case is_admin do
      "yes" -> true
      "no" -> false
      _ -> is_admin
    end
  end

  def get_group_by_name(group_name) do
    MockTdAuthService.get_group_by_name(group_name)
  end
end
