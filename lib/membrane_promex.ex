defmodule Membrane.PromEx do
  use PromEx.Plugin

  require Logger

  alias Membrane.ComponentPath

  @impl true
  def event_metrics(_opts) do
    now = System.system_time(:second)
    {uptime_ms, _} = :erlang.statistics(:wall_clock)
    beam_start_time = now - div(uptime_ms, 1000)

    for handler <- [:handle_buffer, :handle_setup, :handle_init] do
      Event.build(
        "membrane_#{handler}_duration" |> String.to_atom(),
        [
          last_value([:membrane, :element, handler, :stop, :duration],
            description: "Duration of membrejn #{handler} callback",
            unit: {:native, :millisecond},
            tags: [:spanID, :traceID, :serviceName, :operationName, :parentSpanID, :startTime],
            tag_values: &resolve_membrane_tags(beam_start_time, handler, &1)
          )
        ]
      )
    end
  end

  defp resolve_membrane_tags(trace_id, handler, meta) do
    %{
      spanID: ComponentPath.format(meta.component_path) <> ":" <> to_string(handler),
      traceID: inspect(trace_id) <> ":" <> inspect(hd(meta.component_path)),
      serviceName: to_string(meta.callback_context.name),
      operationName: inspect(handler),
      parentSpanID: "",
      startTime:
        :erlang.convert_time_unit(
          meta.monotonic_time + :erlang.time_offset(),
          :native,
          :millisecond
        )
    }
  end
end
