import Config

if Mix.env() == :test do
  config :membrane_promex, MembranePromEx.PromEx,
    disabled: false,
    manual_metrics_start_delay: :no_delay,
    drop_metrics_groups: [],
    grafana: :disabled,
    metrics_server: :disabled

  config :membrane_promex, MembranePromExTest.Endpoint,
    url: [host: "localhost", port: 4321],
    http: [port: 4321],
    server: true

  config :membrane_core, :telemetry_flags,
    tracked_callbacks: [
      element: :all,
      bin: :all,
      pipeline: :all
    ]
end
