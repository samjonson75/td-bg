defmodule TdBg.Metrics.BusinessConcepts do
  @moduledoc false

  use GenServer
  require Logger
  alias TdBg.Metrics.Instrumenter
  alias TdBg.Taxonomies
  alias TdBg.Templates
  alias TdBg.Utils.CollectionUtils

  @search_service Application.get_env(:td_bg, :elasticsearch)[:search_service]

  @fixed_concepts_count_dimensions [:status, :domain_parents, :q_rule_count, :link_count]
  @fixed_completness_dimensions [:id, :group, :field, :status, :domain_parents]

  @metrics_busines_concepts_on_startup Application.get_env(
                                       :td_bg,
                                       :metrics_busines_concepts_on_startup
                                     )

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    if @metrics_busines_concepts_on_startup do
      Instrumenter.setup()
      schedule_work() # Schedule work to be performed at some point
    end
    {:ok, state}
  end

  def handle_info(:work, state) do
    concepts_count_metrics = get_concepts_count()
    Logger.info("Number of concepts_count metric #{inspect(length(concepts_count_metrics))}")
    Enum.each(concepts_count_metrics, &Instrumenter.set_concepts_count(&1))

    concept_fields_completness_metrics = get_concept_fields_completness()
    Logger.info("Number of concept_fields_completness metric #{inspect(length(concept_fields_completness_metrics))}")
    Enum.each(concept_fields_completness_metrics, &Instrumenter.set_concept_fields_completness(&1))

    schedule_work() # Reschedule once more
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, 1000 * 5) # 5 min
  end

  def get_concepts_count do

    search = %{
      query: %{bool: %{must: %{match_all: %{}}}},
      size: 100
    }

    @search_service.search("business_concept", search)
      |> Map.get(:results)
      |> atomize_concept_map()

      |> Enum.map(&Map.update!(&1, :domain_parents, fn(current) ->
          Enum.map(current, fn(domain) -> domain.name end)
        end))
      |> Enum.map(&Map.update!(&1, :q_rule_count, fn(current) ->
          case current do
            0 -> "No"
            _ -> "Si"
          end
        end))
      |> Enum.map(&Map.update!(&1, :link_count, fn(current) ->
          case current do
            0 -> "No"
            _ -> "Si"
          end
        end))
      |> Enum.map(&include_empty_metrics_dimensions(&1))

      |> Enum.reduce([], fn(elem, acc) -> [Map.put(elem, :count, 1) |acc] end)
      |> Enum.group_by(& Enum.zip(
          get_keys(&1, @fixed_concepts_count_dimensions),
          get_values(&1, @fixed_concepts_count_dimensions))
      )

      |> Enum.map(fn {key, value} ->
          %{dimensions: Enum.into(key, %{}), count: value |> Enum.map(& &1.count) |> Enum.sum()}
        end)
      |> Enum.map(fn (metric) ->
          Map.put(metric, :template_name, get_template(metric.dimensions.domain_parents).name)
        end)
  end

  defp include_empty_metrics_dimensions(concept) do
    IO.inspect("DEBUGGEANDO METRICS")
    IO.inspect(concept)
    Map.put(
      concept,
      :content, Map.merge(Enum.into(get_concept_template_dimensions(concept.type), %{}, fn(dim) -> {dim, ""} end),
      concept.content)
    )
  end

  def get_concept_fields_completness do

    search = %{
      query: %{bool: %{must: %{match_all: %{}}}}
    }

    @search_service.search("business_concept", search)
      |> Map.get(:results)
      |> atomize_concept_map()

      |> Enum.map(&Map.update!(&1, :domain_parents, fn(current) ->
          Enum.map(current, fn(domain) -> domain.name end)
        end))
      |> Enum.map(&include_empty_metrics_dimensions(&1))

      |> Enum.reduce([], fn(concept, acc) ->
          [Enum.reduce(get_not_required_fields(concept), [], fn(field, acc) ->
            case Map.get(concept.content, field) do
              nil -> [%{dimensions: get_map_dimensions(concept, field), count: 0} |acc]
              "" -> [%{dimensions: get_map_dimensions(concept, field), count: 0} |acc]
              _ -> [%{dimensions: get_map_dimensions(concept, field), count: 1} |acc]
            end
          end) |acc]
        end) |> List.flatten

      |> Enum.map(fn (metric) ->
          Map.put(metric, :template_name, get_template(metric.dimensions.domain_parents).name)
        end)
  end

  defp get_map_dimensions(concept, field) do
    Enum.into(Enum.zip(
      get_keys(concept, @fixed_completness_dimensions) ++ [:group, :field],
      get_values(concept, @fixed_completness_dimensions) ++ get_concept_field_and_group(concept, field)),
    %{})
  end

  defp get_keys(concept, fixed_dimensions) do
    Map.keys(Map.take(concept, fixed_dimensions)) ++
    Map.keys(Map.take(concept.content, get_concept_template_dimensions(concept.type)))
  end

  defp get_values(concept, fixed_dimensions) do
    Map.values(Map.take(concept, fixed_dimensions)) ++
    Map.values(Map.take(concept.content, get_concept_template_dimensions(concept.type)))
  end

  defp get_template(domain_parents) do
    List.first(Templates.get_domain_templates(Taxonomies.get_domain_by_name(List.first(domain_parents))))
  end

  defp get_concept_field_and_group(concept, field) do
    group = Templates.get_template_by_name(concept.type).content
      |> Enum.map(fn (x) -> if field == String.to_atom(x["name"]) do x["group"] end end)
      |> Enum.filter(fn(elem) -> !is_nil(elem) end)

    group ++ [field]
  end

  defp get_not_required_fields(concept) do
    Enum.reduce(Map.get(Templates.get_template_by_name(Map.get(concept, :type)), :content), [], fn(field, acc) ->
      if CollectionUtils.atomize_keys(field).required == false do
        acc ++ [String.to_atom(CollectionUtils.atomize_keys(field).name)]
      else
        acc ++ []
      end
    end)
  end

  defp atomize_concept_map(business_concept_version) do
    business_concept_version
    |> Enum.map(&Map.get(&1, "_source"))
    |> Enum.map(&Map.put(&1, "content", CollectionUtils.atomize_keys(Map.get(&1, "content"))))
    |> Enum.map(&Map.put(&1, "domain_parents", Enum.map(Map.get(&1, "domain_parents"), fn(domain) -> CollectionUtils.atomize_keys(domain) end)))
    |> Enum.map(&CollectionUtils.atomize_keys(&1))
  end

  def get_dimensions_from_templates do
    Templates.list_templates()
      |> Enum.map(fn(template) -> %{name: template.name, dimensions: template.content |> Enum.map(fn(content) ->
          get_name_dimension(content) end)}
        end)
      |> Enum.map(&Map.update!(&1, :dimensions, fn(current_dimensions) ->
          Enum.filter(current_dimensions, fn(d) -> !is_nil(d) end)
        end))
  end

  def get_concept_template_dimensions(concept_type) do
    concept_type
      |> Templates.get_template_by_name()
      |> Map.get(:content)
      |> Enum.map(&get_name_dimension(&1))
      |> Enum.filter(&!is_nil(&1))
  end

  defp get_name_dimension(%{"metrics_dimension" => true} = content) do
    String.to_atom(Map.get(content, "name"))
  end
  defp get_name_dimension(_content), do: nil

end
