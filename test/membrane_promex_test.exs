defmodule MembranePromExTest.PromEx do
  use PromEx, otp_app: :membrane_promex

  @impl true
  def plugins do
    [
      Membrane.PromEx
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "prometheus",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    []
  end
end

defmodule MembranePromExTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :membrane_promex

  plug(PromEx.Plug, prom_ex_module: MembranePromExTest.PromEx)
end

defmodule MembranePromExTest do
  use ExUnit.Case

  setup_all do
    setup_server()
    :ok
  end

  test "Metrics exposed properly" do
    assert Req.get!("http://0.0.0.0:4321/metrics").body =~
             "membrane_promex_prom_ex_prom_ex_status_info"
  end

  test "Membrane metrics visible after running a pipeline" do
    pid = self()

    :telemetry.attach(
      :membrane_promex_test,
      [:membrane, :element, :handle_buffer, :stop],
      fn _, _, _, _ ->
        IO.inspect("A")
        send(pid, :done)
      end,
      %{}
    )

    start_membrane_pipeline()

    receive do
      :done -> :ok
    end

    body = Req.get!("http://0.0.0.0:4321/metrics").body

    assert body =~
             "membrane_element_handle_buffer_stop"

    assert body =~
             "operationName=\":handle_buffer\""
  end

  defp setup_server do
    children = [
      MembranePromExTest.PromEx,
      MembranePromExTest.Endpoint
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  def start_membrane_pipeline() do
    alias Membrane.Testing
    import Membrane.ChildrenSpec

    defmodule TestFilter do
      use Membrane.Filter

      def_input_pad(:input, accepted_format: _any)
      def_output_pad(:output, accepted_format: _any)

      def handle_buffer(_pad, buf, _ctx, state) do
        {[buffer: {:output, buf}], state}
      end
    end

    child_spec =
      child(:source, %Testing.Source{output: ["a", "b", "c"]})
      |> child(:filter, TestFilter)
      |> child(:sink, Testing.Sink)

    Testing.Pipeline.start_link_supervised!(spec: child_spec)
  end
end
