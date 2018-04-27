defmodule TdBg.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias TdBg.Repo

  alias TdBg.Permissions.Permission
  alias TdBg.Permissions.AclEntry
  alias TdBg.Permissions.Role
  alias TdBg.Taxonomies.Domain
  alias TdBg.Taxonomies

  @doc """
  Returns the list of permissions.

  ## Examples

      iex> list_permissions()
      [%Permission{}, ...]

  """
  def list_permissions do
    Repo.all(Permission)
  end

  @doc """
  Gets a single permission.

  Raises `Ecto.NoResultsError` if the Permission does not exist.

  ## Examples

      iex> get_permissions!(123)
      %Permission{}

      iex> get_permissions!(456)
      ** (Ecto.NoResultsError)

  """
  def get_permission!(id), do: Repo.get!(Permission, id)

  @doc """
  Returns the list of acl_entries.

  ## Examples

      iex> list_acl_entries()
      [%Acl_entry{}, ...]

  """
  def list_acl_entries do
    Repo.all(AclEntry)
  end

  @doc """
    Returns a list of users-role with acl_entries in the domain passed as argument
  """
  def list_acl_entries(%{domain: domain}) do
    acl_entries = Repo.all(from acl_entry in AclEntry, where: acl_entry.resource_type == "domain" and acl_entry.resource_id == ^domain.id)
    acl_entries |> Repo.preload(:role)
  end

  @doc """

  """
  def list_acl_entries_by_principal(%{principal_id: principal_id, principal_type: principal_type}) do
    acl_entries = Repo.all(from acl_entry in AclEntry, where: acl_entry.principal_type == ^principal_type and acl_entry.principal_id == ^principal_id)
    acl_entries |> Repo.preload(:role)
  end

  @doc """

  """
  def get_acl_entry_by_principal_and_resource(%{user_id: principal_id, resource_type: resource_type, resource_id: resource_id}) do
    Repo.get_by(AclEntry, principal_type: "user", principal_id: principal_id, resource_type: resource_type, resource_id: resource_id)
  end

  @doc """
    Returns acl entry for an user and domain
  """
  def get_acl_entry_by_principal_and_resource(%{user_id: principal_id, domain: domain}) do
    Repo.get_by(AclEntry, principal_type: "user", principal_id: principal_id, resource_type: "domain", resource_id: domain.id)
  end

  @doc """
  Gets a single acl_entry.

  Raises `Ecto.NoResultsError` if the Acl entry does not exist.

  ## Examples

      iex> get_acl_entry!(123)
      %Acl_entry{}

      iex> get_acl_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_acl_entry!(id), do: Repo.get!(AclEntry, id)

  @doc """
  Creates a acl_entry.

  ## Examples

      iex> create_acl_entry(%{field: value})
      {:ok, %Acl_entry{}}

      iex> create_acl_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_acl_entry(attrs \\ %{}) do
    %AclEntry{}
    |> AclEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a acl_entry.

  ## Examples

      iex> update_acl_entry(acl_entry, %{field: new_value})
      {:ok, %Acl_entry{}}

      iex> update_acl_entry(acl_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_acl_entry(%AclEntry{} = acl_entry, attrs) do
    acl_entry
    |> AclEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Acl_entry.

  ## Examples

      iex> delete_acl_entry(acl_entry)
      {:ok, %Acl_entry{}}

      iex> delete_acl_entry(acl_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_acl_entry(%AclEntry{} = acl_entry) do
    Repo.delete(acl_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking acl_entry changes.

  ## Examples

      iex> change_acl_entry(acl_entry)
      %Ecto.Changeset{source: %Acl_entry{}}

  """
  def change_acl_entry(%AclEntry{} = acl_entry) do
    AclEntry.changeset(acl_entry, %{})
  end

  @doc """
    Returns Role with name role_name
  """
  def get_role_by_name(role_name) do
    Repo.get_by(Role, name: String.downcase(role_name))
  end

  @doc """
    Returns role of user in domain
  """
  def get_role_in_resource(%{user_id: principal_id, domain_id: resource_id}) do
    domain = Taxonomies.get_domain(resource_id)
    domain = domain |> Repo.preload(:parent)
    role_name = get_resource_role(%{user_id: principal_id, domain: domain, role: nil})
    case role_name do
      nil -> nil
      name -> %Role{name: name}
    end
  end

  defp get_resource_role(%{user_id: _principal_id, domain: %Domain{parent_id: nil}, role: nil} = attrs) do
    case get_role_by_principal_and_resource(attrs) do
      nil -> nil
      %Role{name: name} ->
        name
    end
  end

  defp get_resource_role(%{user_id: _principal_id, domain: %Domain{parent_id: nil}, role: role} = attrs) do
    case get_role_by_principal_and_resource(attrs) do
      nil ->
        role.name
      %Role{name: name} ->
        name
    end
  end

  defp get_resource_role(%{user_id: principal_id, domain: %Domain{} = domain, role: nil} = attrs) do
    role = get_role_by_principal_and_resource(attrs)
    parent_domain = Taxonomies.get_domain(domain.parent_id)
    parent_domain = parent_domain |> Repo.preload(:parent)
    get_resource_role(%{user_id: principal_id, role: role, domain: parent_domain})
  end

  defp get_resource_role(%{user_id: _principal_id, domain: %Domain{} = _domain, role: role}) do
    role.name
  end

  defp get_role_by_principal_and_resource(%{user_id: _principal_id, domain: %Domain{}} = attrs) do
    acl_entry =
      case get_acl_entry_by_principal_and_resource(attrs) do
        nil ->  nil
        acl_entry -> acl_entry |> Repo.preload(:role)
      end
    case acl_entry do
      nil -> nil
      acl_entry -> acl_entry.role
    end
  end

  alias TdBg.Permissions.Role

  @doc """
  Returns the list of roles.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    Repo.all(Role)
  end

  @doc """
  Gets a single role.

  Raises `Ecto.NoResultsError` if the Role does not exist.

  ## Examples

      iex> get_role!(123)
      %Role{}

      iex> get_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_role!(id), do: Repo.get!(Role, id)

  @doc """
  Creates a role.

  ## Examples

      iex> create_role(%{field: value})
      {:ok, %Role{}}

      iex> create_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a role.

  ## Examples

      iex> update_role(role, %{field: new_value})
      {:ok, %Role{}}

      iex> update_role(role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_role(%Role{} = role, attrs) do
    role
    |> Role.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Role.

  ## Examples

      iex> delete_role(role)
      {:ok, %Role{}}

      iex> delete_role(role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_role(%Role{} = role) do
    Repo.delete(role)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking role changes.

  ## Examples

      iex> change_role(role)
      %Ecto.Changeset{source: %Role{}}

  """
  def change_role(%Role{} = role) do
    Role.changeset(role, %{})
  end

  @doc """
  Returns the list of Permissions asociated to a Role.

  ## Examples

      iex> get_role_permissions()
      [%Permission{}, ...]

  """
  def get_role_permissions(%Role{} = role) do
    role
    |> Repo.preload(:permissions)
    |> Map.get(:permissions)
  end

  @doc """
  Associate Permissions to a Role.

  ## Examples

      iex> add_permissions_to_role!()
      %Role{}

  """
  def add_permissions_to_role(%Role{} = role, permissions) do
    role
    |> Repo.preload(:permissions)
    |> Changeset.change
    |> Changeset.put_assoc(:permissions, permissions)
    |> Repo.update!
  end

  @doc """
  Check if user has a permission in a domain.

  ## Examples

      iex> authorized?()
      true

  """
  def authorized?(%{user_id: user_id, permission: permission, domain_id: domain_id}) do
    acl_input = %{user_id: user_id, domain_id: domain_id}
    role_in_resource = get_role_in_resource(acl_input)
    case role_in_resource do
      nil -> false
      role ->
        role
        |> Map.get(:name)
        |> get_role_by_name
        |> Repo.preload(:permissions)
        |> Map.get(:permissions)
        |> Enum.map(&(&1.name))
        |> Enum.member?(permission)
    end
  end

  @doc """
    Returns flat list of DG and DDs user roles
  """
  def assemble_roles(%{user_id: user_id}) do
    tree = Taxonomies.tree()
    acls = list_acl_entries_by_principal(%{principal_id: user_id, principal_type: "user"})
    domains = Taxonomies.list_domains()
    roles = Enum.reduce(tree, [], fn(node, acc) ->
      branch_roles = assemble_node_role(node, user_id, acls, [], domains)
      Enum.uniq(List.flatten(acc ++ branch_roles))
    end)
    roles
  end

  defp build_domain_map(%{"id": id, "role": role, "acl_entry_id": acl_entry_id, "inherited": inherited}) do
    %{"id": id, "role": role, "acl_entry_id": acl_entry_id, "inherited": inherited}
  end

  defp assemble_node_role(%Domain{parent_id: nil} = domain, user_id, all_acls, roles, domains) do
    custom_role = get_role_in_resource(%{user_id: user_id, domain_id: domain.id})
    custom_acl = Enum.find(all_acls, fn(acl) -> acl.resource_type == "domain" && acl.resource_id == domain.id end)
    custom_role_name = if custom_role do
      custom_role.name
    else
      nil
    end
    custom_acl_id = if custom_acl do
      custom_acl.id
    else
      nil
    end
    roles = roles ++ [build_domain_map(%{id: domain.id, role: custom_role_name, acl_entry_id: custom_acl_id, inherited: custom_acl == nil})]
    Enum.reduce(domain.children, roles, fn(child_domain, acc) ->
      Enum.uniq(List.flatten(acc ++ [assemble_node_role(child_domain, user_id, all_acls, roles, domains)]))
    end)
  end

  defp assemble_node_role(%Domain{} = domain, user_id, all_acls, roles, domains) do
    custom_acl = Enum.find(all_acls, fn(acl) -> acl.resource_type == "domain" && acl.resource_id == domain.id end)
    roles = if custom_acl do
      roles ++ [build_domain_map(%{id: domain.id, role: custom_acl.role.name, acl_entry_id: custom_acl.id, inherited: false})]
    else
      roles ++ [get_closest_role(domain, roles, domains)]
    end
    Enum.reduce(domain.children, roles, fn(child_domain, acc) ->
      Enum.uniq(List.flatten(acc ++ [assemble_node_role(child_domain, user_id, all_acls, roles, domains)]))
    end)
  end

  defp get_closest_role(%Domain{} = domain, roles, domains) do
    role = Enum.find(roles, fn(role) -> role.id == domain.parent_id end)
    if role do
      build_domain_map(%{id: domain.id, role: role.role, acl_entry_id: nil, inherited: true})
    else
      parent_domain = Enum.find(domains, fn(d) -> d.id == domain.parent_id end)
      get_closest_role(parent_domain, roles, domains)
    end
  end
end
