defmodule TdBg.RolesAdminTest do
  use Cabbage.Feature, async: false, file: "roles_admin.feature"
  use TdBgWeb.FeatureCase
  import TdBgWeb.Router.Helpers
  import TdBgWeb.ResponseCode
  import TdBgWeb.Taxonomy
  import TdBgWeb.Authentication, only: :functions
  import TdBgWeb.User, only: :functions
  alias Poison, as: JSON
  @endpoint TdBgWeb.Endpoint

  #Scenario
  defgiven ~r/^an existing Domain Group called "(?<name>[^"]+)"$/, %{name: name}, state do
    token_admin = get_user_token("app-admin")
    state = Map.merge(state, %{token_admin: token_admin})
    {:ok, status_code, _json_resp} = domain_group_create(state[:token_admin],  %{name: name})
    assert rc_created() == to_response_code(status_code)
    {:ok, state}
  end

  defand ~r/^an existing Data Domain called "(?<name>[^"]+)" child of Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{name: name, domain_group_name: domain_group_name}, state do
    domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
    {:ok, _status_code, json_resp} = data_domain_create(state[:token_admin],  %{name: name, domain_group_id: domain_group_info["id"]})
    assert json_resp["data"]["domain_group_id"] == domain_group_info["id"]
    {:ok, state}
  end

  defand ~r/^following users exist with the indicated role in Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{domain_group_name: domain_group_name, table: table}, state do

    domain_group = get_domain_group_by_name(state[:token_admin], domain_group_name)
    Enum.map(table, fn(x) ->
        user_name = x[:user]
        role_name = x[:role]
        principal_id = create_user(user_name).id
        %{"id" => role_id} = get_role_by_name(state[:token_admin], role_name)
        acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "domain_group", resource_id: domain_group["id"], role_id: role_id}
        {:ok, _, _json_resp} = acl_entry_create(state[:token_admin], acl_entry_params)
        {:ok, _, json_resp} = user_domain_group_role(state[:token_admin], %{user_id: principal_id, domain_group_id: domain_group["id"]})
        assert json_resp["data"]["name"] == role_name
      end)
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Domain Group "(?<resource_name>[^"]+)"$/,
    %{user_name: user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do

    domain_group_info = get_domain_group_by_name(state[:token_admin], resource_name)
    principal_id = create_user(principal_name).id
    role_info = get_role_by_name(state[:token_admin], role_name)
    acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "domain_group", resource_id: domain_group_info["id"], role_id: role_info["id"]}

    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defthen ~r/^the system returns a result with code "(?<status_code>[^"]+)"$/, %{status_code: status_code}, state do
    assert status_code == to_response_code(state[:status_code])
  end

  #And if result <result> is "Created", Data Domain "My Data Domain" is a child of Domain Group "My Group"
  defand ~r/^if result "(?<actual_result>[^"]+)" is "(?<expected_result>[^"]+)", the user "(?<user_name>[^"]+)" has "(?<role_name>[^"]+)" role in Domain Group "(?<domain_group_name>[^"]+)"$/,
    %{actual_result: actual_result, expected_result: expected_result, user_name: user_name, role_name: role_name, domain_group_name: domain_group_name}, state do
    if actual_result == expected_result do
      domain_group_info = get_domain_group_by_name(state[:token_admin], domain_group_name)
      principal_id = create_user(user_name).id
      acl_entry_params = %{user_id: principal_id, domain_group_id: domain_group_info["id"]}
      {:ok, _status_code, json_resp} = user_domain_group_role(state[:token_admin], acl_entry_params)
      assert json_resp["data"]["name"] == role_name
    end
  end

  #And if result <result> is "Created", Data Domain "My Data Domain" is a child of Domain Group "My Group"
  defand ~r/^if result "(?<actual_result>[^"]+)" is "(?<expected_result>[^"]+)", the user "(?<user_name>[^"]+)" has "(?<role_name>[^"]+)" role in Data Domain "(?<data_domain_name>[^"]+)"$/,
    %{actual_result: actual_result, expected_result: expected_result, user_name: user_name, role_name: role_name, data_domain_name: data_domain_name}, state do
    if actual_result == expected_result do
      data_domain_info = get_data_domain_by_name(state[:token_admin], data_domain_name)
      principal_id = create_user(user_name).id
      acl_entry_params = %{user_id: principal_id, data_domain_id: data_domain_info["id"]}
      {:ok, _status_code, json_resp} = user_data_domain_role(state[:token_admin], acl_entry_params)
      assert json_resp["data"]["name"] == role_name
    end
  end

  defand ~r/^following users exist with the indicated role in Data Domain "(?<data_domain_name>[^"]+)"$/,
         %{data_domain_name: data_domain_name, table: table}, state do

    data_domain = get_data_domain_by_name(state[:token_admin], data_domain_name)
    Enum.map(table, fn(x) ->
      user_name = x[:user]
      role_name = x[:role]
      principal_id = create_user(user_name).id
      %{"id" => role_id} = get_role_by_name(state[:token_admin], role_name)
      acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "data_domain", resource_id: data_domain["id"], role_id: role_id}
      {:ok, _, _json_resp} = acl_entry_create(state[:token_admin], acl_entry_params)
      {:ok, _, json_resp} = user_data_domain_role(state[:token_admin], %{user_id: principal_id, data_domain_id: data_domain["id"]})
      assert json_resp["data"]["name"] == role_name
    end)
  end

  defwhen ~r/^"(?<user_name>[^"]+)" grants (?<role_name>[^"]+) role to user "(?<principal_name>[^"]+)" in Data Domain "(?<resource_name>[^"]+)"$/,
          %{user_name: user_name, role_name: role_name, principal_name: principal_name, resource_name: resource_name}, state do

    data_domain_info = get_data_domain_by_name(state[:token_admin], resource_name)
    principal_id = create_user(principal_name).id
    role_info = get_role_by_name(state[:token_admin], role_name)
    acl_entry_params = %{principal_type: "user", principal_id: principal_id, resource_type: "data_domain", resource_id: data_domain_info["id"], role_id: role_info["id"]}

    token = get_user_token(user_name)
    {_, status_code, json_resp} = acl_entry_create(token , acl_entry_params)
    {:ok, Map.merge(state, %{status_code: status_code,  resp: json_resp})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" lists all users with custom permissions in Data Domain "(?<data_domain_name>[^"]+)"$/,
    %{user_name: user_name, data_domain_name: data_domain_name}, state do
    token = get_user_token(user_name)
    data_domain_info = get_data_domain_by_name(token, data_domain_name)
    {:ok, 200,  %{"data" => users_roles}} = data_domain_users_roles(token, %{id: data_domain_info["id"]})
    {:ok, Map.merge(state, %{users_roles: users_roles})}
  end

  defthen ~r/^the system returns a result with following data:$/,
    %{table: expected_list}, state do

    actual_list = state[:users_roles]
    expected_list = Enum.reduce(expected_list, [], fn(item, acc) ->
      nitem = Map.new(item, fn {k, v} -> {Atom.to_string(k), v} end)
      acc ++ [nitem]
    end
    )
    assert Enum.sort(actual_list) == Enum.sort(expected_list)
  end

  defand ~r/^following users exist in the application:$/, %{table: users}, state do
    existing_users = Enum.map(users, fn(user) ->
      new_user = create_user(user.user)
      assert new_user != nil
      new_user
    end)
    {:ok, Map.merge(state, %{existing_users: existing_users})}
  end

  defwhen ~r/^"(?<user_name>[^"]+)" tries to list all users available to set custom permissions in Domain Group "(?<domain_group>[^"]+)"$/,
          %{user_name: user_name, domain_group: domain_group_name}, state do
    token = get_user_token(user_name)
    headers = get_header(token)
    domain_group = get_domain_group_by_name(token, domain_group_name)
    {:ok, %HTTPoison.Response{status_code: status_code, body: resp}} =
      HTTPoison.get(domain_group_domain_group_url(@endpoint, :available_users, domain_group["id"]), headers, [])
    users = resp |> JSON.decode!
    {:ok, Map.merge(state, %{status_code: status_code, users: users})}
  end

  defthen ~r/^the system returns an user list with following data:$/, %{table: users}, state do
    existing_users = state[:existing_users]
    all_available_users = state[:users]["data"]
    available_users = Enum.filter(all_available_users, fn(user) -> Enum.find(existing_users, fn(existing) -> user["user_name"] == existing.user_name  end)  end)
    Enum.each(users, fn(user) ->
      match_user = Enum.find(available_users, fn(available) ->
        user.user == available["user_name"]
      end)
      assert match_user
    end)
  end

  defp data_domain_users_roles(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(data_domain_data_domain_url(@endpoint, :users_roles, attrs.id), [], headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp user_domain_group_role(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_domain_group_role_url(@endpoint, :user_domain_group_role, attrs.user_id, attrs.domain_group_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp user_data_domain_role(token, attrs) do
    headers = get_header(token)
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.get!(user_data_domain_role_url(@endpoint, :user_data_domain_role, attrs.user_id, attrs.data_domain_id), headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end

  defp acl_entry_create(token, acl_entry_params) do
    headers = get_header(token)
    body = %{acl_entry: acl_entry_params} |> JSON.encode!
    %HTTPoison.Response{status_code: status_code, body: resp} =
      HTTPoison.post!(acl_entry_url(@endpoint, :create), body, headers, [])
    {:ok, status_code, resp |> JSON.decode!}
  end
end
