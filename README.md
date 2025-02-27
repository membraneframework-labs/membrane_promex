# Membrane Telemetry PromEx Plugin

## Installation

The package can be installed by adding `membrane_promex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_template_plugin, git: "git@github.com:membraneframework/membrane_promex.git"}
  ]
end
```

## Usage

Set up Promex according to their [most recent documentation](https://github.com/akoutmos/prom_ex?tab=readme-ov-file#setting-up-promex)
Then in your PromEx module add: 
```elixir
use Membrane.PromEx
```

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_template_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_template_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
