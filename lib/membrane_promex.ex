defmodule Membrane.PromEx do
  use PromEx.Plugin

  require Logger

  alias Membrane.ComponentPath

  @impl true
  def event_metrics(_opts) do
    now = System.system_time(:second)
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    beam_start_time = now - div(uptime_ms, 1000)

    for {component, handlers} <- Membrane.Telemetry.tracked_callbacks(),
        handler <- handlers do
      Event.build(
        "membrane_#{component}_#{handler}_duration" |> String.to_atom(),
        [
          last_value([:membrane, component, handler, :stop, :duration],
            description: "Duration of membrane #{handler} callback",
            unit: {:native, :millisecond},
            tags: [
              :spanID,
              :traceID,
              :serviceName,
              :operationName,
              :parentSpanID,
              :startTime,
              :serviceTags
            ],
            tag_values: &resolve_membrane_tags(beam_start_time, handler, &1)
          )
        ]
      )
    end
  end

  defp resolve_membrane_tags(trace_id, handler, meta) do
    pipeline_pid = pid(hd(meta.component_path))
    pipeline_name = name_or_pid(pipeline_pid)

    service_tags =
      for {k, v} <- meta.callback_context,
          do: %{key: to_string(k), value: inspect(v)}

    %{
      spanID: ComponentPath.format(meta.component_path) <> ":" <> to_string(handler),
      traceID: "#{inspect(trace_id)}:#{pipeline_name}",
      serviceName: get_name(meta.callback_context),
      operationName: inspect(handler),
      parentSpanID: "",
      startTime:
        :erlang.convert_time_unit(
          meta.monotonic_time + :erlang.time_offset(),
          :native,
          :millisecond
        ),
      serviceTags: Jason.encode!(service_tags)
    }
  end

  defp get_name(%{name: name}) do
    name
  end

  defp get_name(%{module: module}) do
    module |> inspect()
  end

  defp name_or_pid(pid) do
    case Process.info(pid, :registered_name) do
      {:registered_name, []} -> inspect(pid)
      {:registered_name, name} -> to_string(name)
    end
  end

  defp pid(string) do
    string
    |> String.replace("/", "")
    |> String.to_charlist()
    |> :erlang.list_to_pid()
  end
end
