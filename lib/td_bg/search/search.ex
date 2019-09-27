defmodule TdBg.Search do
  alias Elasticsearch.Index.Bulk
  alias Jason, as: JSON
  alias TdBg.BusinessConcepts.BusinessConceptVersion
  alias TdBg.ESClientApi
  alias TdBg.Search.Cluster
  alias TdBg.Taxonomies.Domain

  require Logger

  @moduledoc """
  Search Engine calls
  """

  def put_bulk_search(:business_concept) do
    Elasticsearch.Index.hot_swap(Cluster, "concepts")
  end

  def put_bulk_search(business_concepts, :business_concept) do
    # TODO: stream, chunk
    bulk = business_concepts
    |> Enum.map(&Bulk.encode!(Cluster, &1, "concepts", [type: "_doc", action: "index"]))
    |> Enum.join("")

    Elasticsearch.post(Cluster, "_bulk", bulk)
  end

  # CREATE AND UPDATE
  def put_search(%BusinessConceptVersion{} = concept) do
    search_fields = concept.__struct__.search_fields(concept)

    response =
      ESClientApi.index_content(
        concept.__struct__.index_name(),
        concept.id,
        search_fields |> JSON.encode!()
      )

    case response do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        Logger.info("Business concept #{concept.name} created/updated status #{status}")

      {:error, _error} ->
        Logger.error("ES: Error creating/updating business concept #{concept.name}")
    end
  end

  # DELETE
  def delete_search(%Domain{} = domain) do
    response = ESClientApi.delete_content("domain", domain.id)

    case response do
      {_, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("Domain #{domain.name} deleted status 200")

      {_, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error("ES: Error deleting domain #{domain.name} status #{status_code}")

      {:error, %HTTPoison.Error{reason: :econnrefused}} ->
        Logger.error("Error connecting to ES")
    end
  end

  def delete_search(%BusinessConceptVersion{} = concept) do
    response = ESClientApi.delete_content("business_concept", concept.id)

    case response do
      {_, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("Business concept #{concept.name} deleted status 200")

      {_, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error("ES: Error deleting business concept #{concept.name} status #{status_code}")

      {:error, %HTTPoison.Error{reason: :econnrefused}} ->
        Logger.error("Error connecting to ES")
    end
  end

  def search(index_name, query) do
    Logger.debug(fn -> "Query: #{inspect(query)}" end)
    response = ESClientApi.search_es(index_name, query)

    case response do
      {:ok, %HTTPoison.Response{body: %{"hits" => %{"hits" => results, "total" => total}}}} ->
        %{results: results, total: total}

      {:ok, %HTTPoison.Response{body: error}} ->
        error
    end
  end

  def get_filters(query) do
    response = ESClientApi.search_es("business_concept", query)

    case response do
      {:ok, %HTTPoison.Response{body: %{"aggregations" => aggregations}}} ->
        aggregations
        |> Map.to_list()
        |> Enum.into(%{}, &filter_values/1)

      {:ok, %HTTPoison.Response{body: error}} ->
        error
    end
  end

  defp filter_values({name, %{"buckets" => buckets}}) do
    {name, buckets |> Enum.map(& &1["key"])}
  end

  defp filter_values({name, %{"distinct_search" => distinct_search}}) do
    filter_values({name, distinct_search})
  end
end
