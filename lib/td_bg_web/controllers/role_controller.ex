defmodule TdBgWeb.RoleController do
  use TdBgWeb, :controller
  use PhoenixSwagger

  alias TdBg.Permissions
  alias TdBg.Permissions.Role
  alias TdBgWeb.SwaggerDefinitions

  action_fallback TdBgWeb.FallbackController

  def swagger_definitions do
    SwaggerDefinitions.role_swagger_definitions()
  end

  swagger_path :index do
    get "/roles"
    description "List Roles"
    response 200, "OK", Schema.ref(:RolesResponse)
  end

  def index(conn, _params) do
    roles = Permissions.list_roles()
    render(conn, "index.json", roles: roles)
  end

  swagger_path :create do
    post "/roles"
    description "Creates a Role"
    produces "application/json"
    parameters do
      role :body, Schema.ref(:RoleCreateUpdate), "Role create attrs"
    end
    response 201, "Created", Schema.ref(:RoleResponse)
    response 400, "Client Error"
  end

  def create(conn, %{"role" => role_params}) do
    with {:ok, %Role{} = role} <- Permissions.create_role(role_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", role_path(conn, :show, role))
      |> render("show.json", role: role)
    end
  end

  swagger_path :show do
    get "/roles/{id}"
    description "Show Role"
    produces "application/json"
    parameters do
      id :path, :integer, "Role ID", required: true
    end
    response 200, "OK", Schema.ref(:RoleResponse)
    response 400, "Client Error"
  end

  def show(conn, %{"id" => id}) do
    role = Permissions.get_role!(id)
    render(conn, "show.json", role: role)
  end

  swagger_path :update do
    put "/roles/{id}"
    description "Updates Role"
    produces "application/json"
    parameters do
      data_domain :body, Schema.ref(:RoleCreateUpdate), "Role update attrs"
      id :path, :integer, "Role ID", required: true
    end
    response 200, "OK", Schema.ref(:RoleResponse)
    response 400, "Client Error"
  end

  def update(conn, %{"id" => id, "role" => role_params}) do
    role = Permissions.get_role!(id)

    with {:ok, %Role{} = role} <- Permissions.update_role(role, role_params) do
      render(conn, "show.json", role: role)
    end
  end

  swagger_path :delete do
    delete "/roles/{id}"
    description "Delete Role"
    produces "application/json"
    parameters do
      id :path, :integer, "Role ID", required: true
    end
    response 204, "OK"
    response 400, "Client Error"
  end

  def delete(conn, %{"id" => id}) do
    role = Permissions.get_role!(id)
    with {:ok, %Role{}} <- Permissions.delete_role(role) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :user_domain_role do
    get "/users/{user_id}/domains/{domain_id}/roles"
    produces "application/json"
    parameters do
      user_id :path, :integer, "user id", required: true
      domain_id :path, :integer, "domain id", required: true
    end
    response 200, "OK", Schema.ref(:RolesResponse)
    response 400, "Client Error"
  end

  def user_domain_role(conn, %{"user_id" => user_id, "domain_id" => domain_id}) do
    role = Permissions.get_role_in_resource(%{user_id: user_id, domain_id: domain_id})
    render(conn, "show.json", role: role)
  end

end
