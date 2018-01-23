defmodule TrueBGWeb.DomainGroupController do
  use TrueBGWeb, :controller

  alias TrueBG.Taxonomies
  alias TrueBG.Taxonomies.DomainGroup

  action_fallback TrueBGWeb.FallbackController

  def index(conn, _params) do
    domain_groups = Taxonomies.list_domain_groups()
    render(conn, "index.json", domain_groups: domain_groups)
  end

  defp get_parent_by_id(parent_id) do
    if parent_id do
      parent = Taxonomies.get_domain_group(parent_id)
      if parent == nil do
        {:error, nil}
      else
        {:ok, parent}
      end
    else
      {:ok, nil}
    end
  end

  def create(conn, %{"domain_group" => domain_group_params}) do
    parent_id = if Map.has_key?(domain_group_params, "parent_id"), do: domain_group_params["parent_id"], else: nil
    parent_info = get_parent_by_id(parent_id)
    case parent_info do
      {:ok, _parent} ->
        with {:ok, %DomainGroup{} = domain_group} <- Taxonomies.create_domain_group(domain_group_params) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", domain_group_path(conn, :show, domain_group))
          |> render("show.json", domain_group: domain_group)
        end
      {:error, _} ->
        conn
          |> put_status(:not_found)
          |> render(ErrorView, :"404.json")
        _ ->
          conn
            |> put_status(:internal_server_error)
            |> render(ErrorView, :"500.json")
    end
  end

  def show(conn, %{"id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    render(conn, "show.json", domain_group: domain_group)
  end

  def update(conn, %{"id" => id, "domain_group" => domain_group_params}) do
    domain_group = Taxonomies.get_domain_group!(id)

    with {:ok, %DomainGroup{} = domain_group} <- Taxonomies.update_domain_group(domain_group, domain_group_params) do
      render(conn, "show.json", domain_group: domain_group)
    end
  end

  def delete(conn, %{"id" => id}) do
    domain_group = Taxonomies.get_domain_group!(id)
    with {:ok, %DomainGroup{}} <- Taxonomies.delete_domain_group(domain_group) do
      send_resp(conn, :no_content, "")
    end
  end
end
