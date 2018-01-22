defmodule TrueBGWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  alias TrueBG.Auth.Guardian
  alias TrueBG.Accounts
  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.ConnTest

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import TrueBGWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint TrueBGWeb.Endpoint
    end
  end

  @admin_user_name "app-admin"

  setup tags do
    :ok = Sandbox.checkout(TrueBG.Repo)
    unless tags[:async] do
      Sandbox.mode(TrueBG.Repo, {:shared, self()})
    end

    cond do
      tags[:admin_authenticated] ->
        user = Accounts.get_user_by_name(@admin_user_name)
        {:ok, jwt, full_claims} = Guardian.encode_and_sign(user)
        {:ok, %{conn: ConnTest.build_conn(), jwt: jwt, claims: full_claims}}
      tags[:authenticated_user] ->
        user = Accounts.get_user_by_name(tags[:authenticated_user])
        {:ok, jwt, full_claims} = Guardian.encode_and_sign(user)
        {:ok, %{conn: ConnTest.build_conn(), jwt: jwt, claims: full_claims}}
       true ->
         {:ok, conn: ConnTest.build_conn()}
    end
  end
end
