defmodule Mahaul.Helpers do
  @moduledoc """
  Basic helpers for parsing and validating the system environment variables.
  """

  require Logger

  @type var_type :: :str | :num | :int | :bool | :port | :host | :uri
  @type success_type :: {:ok, atom | binary | number}
  @type error_type :: {:error, nil}
  @type parsed_vars_type :: list
  @type config_type :: keyword

  @env Mix.env()
  @error_tuple {:error, nil}

  @spec validate!(parsed_vars_type) :: nil
  def validate!(parsed_envs) do
    case validate(parsed_envs) do
      {:ok} -> nil
      {:error, _errors} -> raise "Invalid environment variables!"
    end
  end

  @spec validate(parsed_vars_type) :: {:ok} | {:error, binary}
  def validate(parsed_envs) do
    errors =
      parsed_envs
      |> Enum.filter(&(elem(&1, 1) == @error_tuple))
      |> Enum.map_join("\n", &Atom.to_string(elem(&1, 0)))

    case errors do
      "" ->
        {:ok}

      _ ->
        Logger.warn("""
        #{__MODULE__}: missing or invalid environment variables.
        #{errors}
        """)

        {:error, errors}
    end
  end

  @spec parse_all(config_type) :: parsed_vars_type
  def parse_all(opts) do
    Enum.map(opts, &get_normalized_val/1)
  end

  @spec get_normalized_val({atom, config_type}) :: {atom, error_type | success_type}
  def get_normalized_val({key, config}) do
    parsed_env = get_env(key, config)
    choices = Keyword.get(config, :choices)

    case parsed_env do
      @error_tuple ->
        {key, parsed_env}

      {:ok, env_val} when not is_nil(choices) and is_list(choices) ->
        if env_val in choices, do: {key, parsed_env}, else: {key, @error_tuple}

      _ ->
        {key, parsed_env}
    end
  end

  @spec get_env(atom, config_type) :: error_type | success_type
  def get_env(key, config) do
    env_name = Atom.to_string(key)
    env_type = Keyword.get(config, :type)
    env_val = System.get_env(env_name) |> get_env_val_or_default(config)

    if is_nil(env_val), do: @error_tuple, else: parse(env_val, env_type)
  end

  defp get_env_val_or_default(env_val, config, mix_env \\ @env)

  defp get_env_val_or_default(env_val, config, mix_env) when mix_env in [:dev, :test] do
    env_val || Keyword.get(config, :default_dev) || Keyword.get(config, :default)
  end

  defp get_env_val_or_default(env_val, config, _mix_env) do
    env_val || Keyword.get(config, :default)
  end

  @doc ~S"""

  #### :str

      iex> Mahaul.Helpers.parse("some value", :str)
      {:ok, "some value"}

  #### :num

      iex> Mahaul.Helpers.parse("10", :num)
      {:ok, 10.0}

      iex> Mahaul.Helpers.parse("10.2345", :num)
      {:ok, 10.2345}

      iex> Mahaul.Helpers.parse("some value", :num)
      {:error, nil}

  #### :int

      iex> Mahaul.Helpers.parse("10", :int)
      {:ok, 10}

      iex> Mahaul.Helpers.parse("10.2345", :int)
      {:error, nil}

      iex> Mahaul.Helpers.parse("some value", :int)
      {:error, nil}

  #### :bool

      iex> Mahaul.Helpers.parse(true, :bool)
      {:ok, true}

      iex> Mahaul.Helpers.parse(false, :bool)
      {:ok, false}

      iex> Mahaul.Helpers.parse("true", :bool)
      {:ok, true}

      iex> Mahaul.Helpers.parse("false", :bool)
      {:ok, false}

      iex> Mahaul.Helpers.parse("1", :bool)
      {:ok, true}

      iex> Mahaul.Helpers.parse("0", :bool)
      {:ok, false}

  #### :port

      iex> Mahaul.Helpers.parse("1", :port)
      {:ok, 1}

      iex> Mahaul.Helpers.parse("65535", :port)
      {:ok, 65535}

      iex> Mahaul.Helpers.parse("8080", :port)
      {:ok, 8080}

      iex> Mahaul.Helpers.parse("some value", :port)
      {:error, nil}

      iex> Mahaul.Helpers.parse("-1", :port)
      {:error, nil}

      iex> Mahaul.Helpers.parse("0", :port)
      {:error, nil}

      iex> Mahaul.Helpers.parse("65536", :port)
      {:error, nil}

  #### :host

      iex> Mahaul.Helpers.parse("//localhost", :host)
      {:ok, "//localhost"}

      iex> Mahaul.Helpers.parse("//domain.com", :host)
      {:ok, "//domain.com"}

      iex> Mahaul.Helpers.parse("//192.168.0.1", :host)
      {:ok, "//192.168.0.1"}

      iex> Mahaul.Helpers.parse("ftp://localhost", :host)
      {:error, nil}

      iex> Mahaul.Helpers.parse("https://domain.com", :host)
      {:error, nil}

      iex> Mahaul.Helpers.parse("https", :host)
      {:error, nil}

      iex> Mahaul.Helpers.parse("https://domain.com/something", :host)
      {:error, nil}

  #### :uri

      iex> Mahaul.Helpers.parse("ftp://localhost", :uri)
      {:ok, "ftp://localhost"}

      iex> Mahaul.Helpers.parse("https://domain.com", :uri)
      {:ok, "https://domain.com"}

      iex> Mahaul.Helpers.parse("postgresql://user:pass@localhost:5432/dev_db", :uri)
      {:ok, "postgresql://user:pass@localhost:5432/dev_db"}

      iex> Mahaul.Helpers.parse("//localhost", :uri)
      {:error, nil}

      iex> Mahaul.Helpers.parse("//domain.com", :uri)
      {:error, nil}

      iex> Mahaul.Helpers.parse("//192.168.0.1", :uri)
      {:error, nil}
  """
  @spec parse(binary, var_type) :: error_type | success_type
  def parse(val, :str), do: {:ok, to_string(val)}

  def parse(val, :enum), do: {:ok, String.to_atom(val)}

  def parse(val, :num) do
    case Float.parse(val) do
      {parsed_val, ""} -> {:ok, parsed_val}
      _ -> @error_tuple
    end
  end

  def parse(val, :int) do
    case Integer.parse(val) do
      {parsed_val, ""} -> {:ok, parsed_val}
      _ -> @error_tuple
    end
  end

  def parse(val, :bool) do
    case val do
      val when val in [true, "true", "t", "1"] -> {:ok, true}
      val when val in [false, "false", "f", "0"] -> {:ok, false}
      _ -> @error_tuple
    end
  end

  def parse(val, :port) do
    case Integer.parse(val) do
      {port, ""} when port > 0 and port < 65_536 -> {:ok, port}
      _ -> @error_tuple
    end
  end

  def parse(val, :host) do
    case URI.new(val) do
      {:ok, uri}
      when not is_nil(uri.host) and uri.host != "" and is_nil(uri.path) and is_nil(uri.scheme) ->
        {:ok, val}

      _ ->
        @error_tuple
    end
  end

  def parse(val, :uri) do
    case URI.new(val) do
      {:ok, uri} when not is_nil(uri.host) and uri.host != "" and not is_nil(uri.scheme) ->
        {:ok, val}

      _ ->
        @error_tuple
    end
  end

  def parse(_val, _type), do: @error_tuple
end
