defmodule TdBGWeb.DomainGroupController do
  use TdBGWeb, :controller
  use PhoenixSwagger

  alias TdBGWeb.ErrorView
  alias TdBG.Taxonomies
  alias TdBG.Taxonomies.DomainGroup
  alias TdBGWeb.SwaggerDefinitions
  alias TdBG.Utils.CollectionUtils
  alias Guardian.Plug, as: GuardianPlug
  import Canada

  action_fallback TdBGWeb.FallbackController

  plug :load_and_authorize_resource, model: DomainGroup, id_name: "id", persisted: true, only: [:update, :delete]

  def swagger_definitions do
    SwaggerDefinitions.domain_group_swagger_definitions()
  end

  swagger_path :index do
    get "/domain_groups"
    description "List Domain Groups"
    response 200, "OK", Schema.ref(:DomainGroupsResponse)
  end

  def index(conn, _params) do
    domain_groups = Taxonomies.list_domain_groups()
    render(conn, "index.json", domain_groups: domain_groups)
  end

  swagger_path :index_root do
    get "/domain_groups/index_root"
    description "List Root Domain Group"
    produces "application/json"
    response 200, "OK", Schema.ref(:DomainGroupsResponse)
    response 400, "Client Error"
  end

  def index_root(conn, _params) do
    domain_groups = Taxonomies.list_root_domain_groups()
    render(conn, "index.json", domain_groups: domain_groups)
  end

  swagger_path :index_children do
    get "/domain_groups/{domain_group_id}/index_children"
    description "List non-root Domain Groups"
    produces "application/json"
    parameters do
      domain_group_id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "OK", Schema.ref(:DomainGroupsResponse)
    response 400, "Client Error"
  end

  def index_children(conn, %{"domain_group_id" => id}) do
    domain_groups = Taxonomies.list_domain_group_children(id)
    render(conn, "index.json", domain_groups: domain_groups)
  end

  swagger_path :create do
    post "/domain_groups"
    description "Creates a Domain Group"
    produces "application/json"
    parameters do
      domain_group :body, Schema.ref(:DomainGroupCreate), "Domain Group create attrs"
    end
    response 201, "Created", Schema.ref(:DomainGroupResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"domain_group" => domain_group_params}) do
    current_user = GuardianPlug.current_resource(conn)
    domain_group = %DomainGroup{} |> Map.merge(CollectionUtils.to_struct(DomainGroup, domain_group_params))

    if current_user |> can?(create(domain_group)) do
      do_create(conn, domain_group_params)
    else
      conn
      |> put_status(403)
      |> render(ErrorView, :"403")
    end
  end

  defp do_create(conn, domain_group_params) do
    parent_id = Taxonomies.get_parent_id(domain_group_params)
    status = case parent_id do
      {:ok, _parent} -> Taxonomies.create_domain_group(domain_group_params)
      {:error, _} -> {:error, nil}
    end
    case status do
      {:ok, %DomainGroup{} = domain_group} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", domain_group_path(conn, :show, domain_group))
        |> render("show.json", domain_group: domain_group)
      {:error, %Ecto.Changeset{} = _ecto_changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
      {:error, nil} ->
        conn
        |> put_status(:not_found)
        |> render(ErrorView, :"404.json")
      _ ->
        conn
        |> put_status(:internal_server_error)
        |> render(ErrorView, :"500.json")
    end
  end

  swagger_path :show do
    get "/domain_groups/{id}"
    description "Show Domain Group"
    produces "application/json"
    parameters do
      id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "OK", Schema.ref(:DomainGroupResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    render(conn, "show.json", domain_group: domain_group)
  end

  swagger_path :update do
    put "/domain_groups/{id}"
    description "Updates Domain Group"
    produces "application/json"
    parameters do
      data_domain :body, Schema.ref(:DomainGroupUpdate), "Domain Group update attrs"
      id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "OK", Schema.ref(:DomainGroupResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "domain_group" => domain_group_params}) do
    domain_group = Taxonomies.get_domain_group!(id)

    with {:ok, %DomainGroup{} = domain_group} <- Taxonomies.update_domain_group(domain_group, domain_group_params) do
      render(conn, "show.json", domain_group: domain_group)
    end
  end

  swagger_path :delete do
    delete "/domain_groups/{id}"
    description "Delete Domain Group"
    produces "application/json"
    parameters do
      id :path, :integer, "Domain Group ID", required: true
    end
    response 200, "OK"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    with {:count, :domain_group, 0} <- Taxonomies.count_domain_group_domain_group_children(id),
         {:count, :data_domain, 0} <- Taxonomies.count_domain_group_data_domain_children(id),
         {:ok, %DomainGroup{}} <- Taxonomies.delete_domain_group(domain_group) do
      send_resp(conn, :no_content, "")
    else
      {:count, :domain_group, n}  when is_integer(n) ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
      {:count, :data_domain, n}  when is_integer(n) ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
      _error ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ErrorView, :"422.json")
    end
  end

end