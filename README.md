# Mahaul

[![hex.pm](https://img.shields.io/hexpm/v/mahaul.svg)](https://hex.pm/packages/mahaul)
[![hex.pm](https://img.shields.io/hexpm/l/mahaul.svg)](https://hex.pm/packages/mahaul)
[![Coverage Status](https://coveralls.io/repos/github/emadalam/mahaul/badge.svg?branch=main)](https://coveralls.io/github/emadalam/mahaul?branch=main)


Parse and validate your environment variables easily in Elixir with the following benefits.

* Compile time access guarantees
* Parsed values with accurate elixir data types
* Validation of required values before app boot
* `mix` environment specific defaults and fallbacks

[Read more](#why-this-package) for understanding why to use this package and its benefits. The complete documentation for `mahaul` is [available online at HexDocs](https://hexdocs.pm/mahaul).

## Requirements

Elixir 1.13+

## Installation

- Add `mahaul` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mahaul, "~> 0.4.0"}
  ]
end
```

- Run `mix deps.get`

- Add config in your `config/config.exs` file

```elixir
config :mahaul, mix_env: Mix.env()
```

## Getting started

#### Define the environment variables needed in your app

```elixir
defmodule MyApp.Env do
  use Mahaul,
    DEPLOYMENT_ENV: [
      type: :enum,
      defaults: [dev: "dev", test: "dev"],
      choices: [:dev, :staging, :live]
    ],
    PORT: [type: :port, defaults: [dev: "4000"]],
    DATABASE_URL: [type: :uri, defaults: [dev: "postgresql://user:pass@localhost:5432/app_dev"]],
    ANOTHER_ENV: [type: :host, default: "//localhost"]
end
```

#### Use in `config/runtime.exs`

```elixir
import Config

if config_env() == :dev do
  MyApp.Env.validate()

  config :my_app, MyApp.Endpoint,
    http: [port: MyApp.Env.port()]
end

if config_env() == :prod do
  MyApp.Env.validate!()

  config :my_app, MyApp.Repo,
    url: MyApp.Env.database_url()

  config :my_app, :something,
    another: MyApp.Env.another_env()

  if MyApp.Env.deployment_env() == :staging do
    # configure something more
  end
end
```

#### Use anywhere in the code

```elixir
defmodule MyApp.Magic
  def do_magic(env \\ MyApp.Env.deployment_env())
  def do_magic(:live), do: "Magic on live"
  def do_magic(:staging), do: "Magic on staging"
  def do_magic(:dev), do: "Magic on dev"
end
```

## Supported types

The following type configurations are supported.

| Type    | Elixir Type | Valid Environment variables value                               |
| :------ | :---------- | :-------------------------------------------------------------- |
| `:str`  | String      | Any string                                                      |
| `:enum` | Atom        | Any string                                                      |
| `:num`  | Float       | Any string that can be parsed as float                          |
| `:int`  | Integer     | Any string that can be parsed as integer                        |
| `:bool` | Boolean     | "true" and "1" as `true`; "false" and "0" as `false`            |
| `:port` | Integer     | Any valid port value between "1" to "65535" (casted as integer) |
| `:host` | String      | Any valid host name                                             |
| `:uri`  | String      | Any valid uris                                                  |


## Setting Defaults

Any defaults and fallback values can be set globally using the `default` or for any mix environment using the `defaults` configuration options. Make sure to use the string values same as we set in the actual system environment, as it will be parsed depending upon the provided `type` configuration.

#### Globally

```elixir
defmodule MyApp.Env do
  use Mahaul,
    MY_ENV: [type: :str, default: "Hello World"]
end
```

```
iex -S mix
iex> MyApp.Env.my_env()
Hello World

MY_ENV="Hello Universe" iex -S mix
iex> MyApp.Env.my_env()
Hello Universe
```

#### For any mix environment

```elixir
defmodule MyApp.Env do
  use Mahaul,
    MY_ENV: [
      type: :str,
      defaults: [prod: "Hello Prod", dev: "Hello Dev", test: "Hello Test", custom: "Hello Custom"]
    ]
end
```

```
MIX_ENV=prod iex -S mix
iex> MyApp.Env.my_env()
Hello Prod

MIX_ENV=dev iex -S mix
iex> MyApp.Env.my_env()
Hello Dev

MIX_ENV=test iex -S mix
iex> MyApp.Env.my_env()
Hello Test

MIX_ENV=custom iex -S mix
iex> MyApp.Env.my_env()
Hello Custom

MIX_ENV=prod MY_ENV="Hello World" iex -S mix
iex> MyApp.Env.my_env()
Hello World
```

#### For any mix environment with fallback

```elixir
defmodule MyApp.Env do
  use Mahaul,
    MY_ENV: [
      type: :str,
      default: "Hello World",
      defaults: [prod: "Hello Prod", dev: "Hello Dev", test: "Hello Test"]
    ]
end
```

```
MIX_ENV=prod iex -S mix
iex> MyApp.Env.my_env()
Hello Prod

MIX_ENV=dev iex -S mix
iex> MyApp.Env.my_env()
Hello Dev

MIX_ENV=test iex -S mix
iex> MyApp.Env.my_env()
Hello Test

MIX_ENV=custom iex -S mix
iex> MyApp.Env.my_env()
Hello World

MIX_ENV=custom MY_ENV="Hello Universe" iex -S mix
iex> MyApp.Env.my_env()
Hello Universe
```

## Setting choices list

You can further restrict the parsed values to a predefined list by setting the `choices` option with list of allowed values. Note that the values are parsed first and then matched against the provided list.

```elixir
defmodule MyApp.Env do
  use Mahaul,
    DEPLOYMENT_ENV: [type: :enum, choices: [:dev, :staging, :live]],
    DAY_OF_WEEK: [type: :int, choices: [1, 2, 3, 4, 5, 6, 7]]
end
```

## Why this package

`mahaul` accomplishes the following functionalities for streamlining the environment variables requirements for an elixir app.

#### Compile time access guarantees

Using the meta programming capabilities of Elixir, `mahaul` creates compile time methods for accessing the environment variables. This guarantees that there are no accidental typos during the access of the environment variables from the code.

#### Parsed values with accurate data types

Depending upon the configuration, the access to the predefined environment variables string values are parsed and the correct elixir data types are returned. `mahaul` supports [a wide range](#supported-types) of commonly set environment variable types. It also supports the `choices` options to limit the allowed values for an environment variable.

#### Validation of required values before app boot

Often times we release new versions of the app accessing new environment variables, but we forget to set those for one of our app deployments. This creates nasty bugs that are only discovered when certain parts of the app behaves erratically or fails. With `mahaul`, you can pre-validate the existence of the required environment variables with correct values before booting the app (ideally in `config/runtime.exs`). This ensures that your application will fail to boot unless you have set those environment variables with correct values. This works really well with any cloud deployments that makes new version of your app active and available only after ensuring the new deployment had a successful boot.

#### Defaults and fallbacks

You can [set default values](#setting-defaults) for the production or development environment of your app while configuring `mahaul`. This comes handy when you want some defaults for dev/test environment to let other contributors of your app quickly start the dev environment of your app without worrying to set some needed environment variables. Or have some sensible defaults for production version of your app with flexibility to change the values by setting an environment variable.

## Contributing

Contributions are welcome

### Running tests

Clone the repo and fetch its dependencies:

```sh
git clone https://github.com/emadalam/mahaul.git
cd mahaul
mix deps.get
mix test

# or with coverage threshold
# mix coveralls
```

### Building docs

```sh
MIX_ENV=docs mix docs
```

## LICENSE

See [LICENSE](https://github.com/emadalam/mahaul/blob/main/LICENSE.txt)
