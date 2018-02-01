defmodule TrueBG.Taxonomies do
  @moduledoc """
  The Taxonomies context.
  """

  import Ecto.Query, warn: false
  alias TrueBG.Repo
  alias TrueBG.Taxonomies.DataDomain
  alias TrueBG.Taxonomies.DomainGroup
  alias Ecto.Changeset

  @doc """
  Returns the list of domain_groups.

  ## Examples

      iex> list_domain_groups()
      [%DomainGroup{}, ...]

  """
  def list_domain_groups do
    Repo.all(DomainGroup)
  end

  @doc """
  Returns the list of root domain_groups (no parent)
  """
  def list_root_domain_groups do
    query = from dg in DomainGroup,
                 where: is_nil(dg.parent),
                 select: [dg.name, dg.description]

    # Send the query to the repository
    Repo.all(query)
  end

  @doc """
  Gets a single domain_group.

  Raises `Ecto.NoResultsError` if the Domain group does not exist.

  ## Examples

      iex> get_domain_group!(123)
      %DomainGroup{}

      iex> get_domain_group!(456)
      ** (Ecto.NoResultsError)

  """
  def get_domain_group!(id), do: Repo.get!(DomainGroup, id)

  def get_domain_group(id), do: Repo.get(DomainGroup, id)

  def get_domain_group_by_name(name) do
    Repo.get_by(DomainGroup, name: name)
  end

  @doc """
  Creates a domain_group.

  ## Examples

      iex> create_domain_group(%{field: value})
      {:ok, %DomainGroup{}}

      iex> create_domain_group(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_domain_group(attrs \\ %{}) do
    %DomainGroup{}
    |> DomainGroup.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a domain_group.

  ## Examples

      iex> update_domain_group(domain_group, %{field: new_value})
      {:ok, %DomainGroup{}}

      iex> update_domain_group(domain_group, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_domain_group(%DomainGroup{} = domain_group, attrs) do
    domain_group
    |> DomainGroup.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a DomainGroup.

  ## Examples

      iex> delete_domain_group(domain_group)
      {:ok, %DomainGroup{}}

      iex> delete_domain_group(domain_group)
      {:error, %Ecto.Changeset{}}

  """
  def delete_domain_group(%DomainGroup{} = domain_group) do
    Repo.delete(domain_group)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking domain_group changes.

  ## Examples

      iex> change_domain_group(domain_group)
      %Ecto.Changeset{source: %DomainGroup{}}

  """
  def change_domain_group(%DomainGroup{} = domain_group) do
    DomainGroup.changeset(domain_group, %{})
  end

  @doc """

  """
  def get_parent_id(nil) do
    {:error, nil}
  end
  def get_parent_id(%{"parent_id": nil}) do
    {:ok, nil}
  end
  def get_parent_id(%{"parent_id": parent_id}) do
    get_parent_id(get_domain_group(parent_id))
  end
  def get_parent_id(parent_id) do
    {:ok, parent_id}
  end

  @doc """
  Returns the list of data_domains.

  ## Examples

      iex> list_data_domains()
      [%DataDomain{}, ...]

  """
  def list_data_domains do
    Repo.all(DataDomain)
  end

  def get_data_domain_by_name(name) do
    Repo.get_by(DataDomain, name: name)
  end

  @doc """
  Gets a single data_domain.

  Raises `Ecto.NoResultsError` if the Data domain does not exist.

  ## Examples

      iex> get_data_domain!(123)
      %DataDomain{}

      iex> get_data_domain!(456)
      ** (Ecto.NoResultsError)

  """
  def get_data_domain!(id), do: Repo.get!(DataDomain, id)

  @doc """
  Creates a data_domain.

  ## Examples

      iex> create_data_domain(%{field: value})
      {:ok, %DataDomain{}}

      iex> create_data_domain(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_data_domain(attrs \\ %{}) do
    %DataDomain{}
    |> DataDomain.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a data_domain.

  ## Examples

      iex> update_data_domain(data_domain, %{field: new_value})
      {:ok, %DataDomain{}}

      iex> update_data_domain(data_domain, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_data_domain(%DataDomain{} = data_domain, attrs) do
    data_domain
    |> DataDomain.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a DataDomain.

  ## Examples

      iex> delete_data_domain(data_domain)
      {:ok, %DataDomain{}}

      iex> delete_data_domain(data_domain)
      {:error, %Ecto.Changeset{}}

  """
  def delete_data_domain(%DataDomain{} = data_domain) do
    Repo.delete(data_domain)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking data_domain changes.

  ## Examples

      iex> change_data_domain(data_domain)
      %Ecto.Changeset{source: %DataDomain{}}

  """
  def change_data_domain(%DataDomain{} = data_domain) do
    DataDomain.changeset(data_domain, %{})
  end

  alias TrueBG.Taxonomies.BusinessConcept

  @doc """
  Returns the list of business_concepts.

  ## Examples

      iex> list_business_concepts()
      [%BusinessConcept{}, ...]

  """
  def list_business_concepts do
    Repo.all(BusinessConcept)
  end

  @doc """
  Gets a single business_concept.

  Raises `Ecto.NoResultsError` if the Business concept does not exist.

  ## Examples

      iex> get_business_concept!(123)
      %BusinessConcept{}

      iex> get_business_concept!(456)
      ** (Ecto.NoResultsError)

  """
  def get_business_concept!(id), do: Repo.get!(BusinessConcept, id)

  @string "string"
  @list "list"
  @variable_list "variable list"

  defp  get_ecto_type(type) do
      case type do
        @string -> :string
        @list -> :string
        @variable_list -> {:array, :string}
      end
  end

  defp get_ecto_types(content_schema) do
    item_mapping = fn(item) ->
      name = item |> Map.get("name")
      type = item |> Map.get("type")
      {String.to_atom(name), get_ecto_type(type)}
    end
    content_schema
      |> Enum.map(item_mapping)
      |> Map.new
  end

  defp add_validate_required(changeset, %{"name" => name, "required" => true}) do
    changeset
      |> Changeset.validate_required([String.to_atom(name)])
  end
  defp add_validate_required(changeset, %{}), do: changeset

  defp add_validate_max_length(changeset, %{"name" => name, "max_size" => max_size}) do
      changeset
        |> Changeset.validate_length(String.to_atom(name), max: max_size)
  end
  defp add_validate_max_length(changeset, %{}), do: changeset

  defp add_validate_inclusion(changeset, %{"name" => name, "type" => "list", "values" => values}) do
      changeset
        |> Changeset.validate_inclusion(String.to_atom(name), values)
  end
  defp add_validate_inclusion(changeset, %{}), do: changeset

  defp add_content_validations(changeset, %{} = content_item) do
    changeset
      |> add_validate_required(content_item)
      |> add_validate_max_length(content_item)
      |> add_validate_inclusion(content_item)
  end

  defp add_content_validations(changeset, [tail|head]) do
    changeset
      |> add_content_validations(tail)
      |> add_content_validations(head)
  end
  defp add_content_validations(changeset, []), do: changeset

  @doc """
  Creates a business_concept.

  ## Examples

      iex> create_business_concept(%{field: value})
      {:ok, %BusinessConcept{}}

      iex> create_business_concept(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_business_concept(attrs \\ %{}) do
    # attrs = attrs |> Map.delete(:name)
    changeset = %BusinessConcept{}
      |> BusinessConcept.changeset(attrs)

    apply = changeset
      |> Changeset.apply_action(:insert)

    content = Map.get(attrs, :content) || Map.get(attrs, "content")
    content_schema = Map.get(attrs, :content_schema) ||
                      Map.get(attrs, "content_schema")
    content_ecto_types = get_ecto_types(content_schema)

    content_changeset = {content, content_ecto_types}
      |> Changeset.cast(content, content_ecto_types |> Map.keys())
      |> add_content_validations(content_schema)

    content_apply = content_changeset
      |> Changeset.apply_action(:insert)

    case {changeset.valid?, content_changeset.valid?} do
      {true, true} -> changeset |> Repo.insert()
      {false, _} -> apply
      {true, false} -> content_apply
    end
  end

  @doc """
  Updates a business_concept.

  ## Examples

      iex> update_business_concept(business_concept, %{field: new_value})
      {:ok, %BusinessConcept{}}

      iex> update_business_concept(business_concept, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_business_concept(%BusinessConcept{} = business_concept, attrs) do
    business_concept
    |> BusinessConcept.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a BusinessConcept.

  ## Examples

      iex> delete_business_concept(business_concept)
      {:ok, %BusinessConcept{}}

      iex> delete_business_concept(business_concept)
      {:error, %Ecto.Changeset{}}

  """
  def delete_business_concept(%BusinessConcept{} = business_concept) do
    Repo.delete(business_concept)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking business_concept changes.

  ## Examples

      iex> change_business_concept(business_concept)
      %Ecto.Changeset{source: %BusinessConcept{}}

  """
  def change_business_concept(%BusinessConcept{} = business_concept) do
    BusinessConcept.changeset(business_concept, %{})
  end
end
