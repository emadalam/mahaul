defmodule Mahaul.Constants do
  @moduledoc """
  Common constants and types.
  """

  @typedoc """
  The configuration options type.
  """
  @type config_type :: keyword

  @typedoc """
  The supported environment variable type.
  """
  @type var_type :: :str | :num | :int | :bool | :port | :host | :uri

  @typedoc """
  The supported environment variable value type.
  """
  @type value_type :: atom | binary | number

  @typedoc """
  The common success type.
  """
  @type success_type :: {:ok, value_type}

  @typedoc """
  The common error type.
  """
  @type error_type :: {:error, nil}

  @typedoc """
  The type representing a normalized environment variable value.
  """
  @type normalized_value_type :: {atom, error_type | success_type}

  @typedoc """
  The type representing list of all normalized environment variable values.
  """
  @type normalized_values_type :: list(normalized_value_type)

  @error_tuple {:error, nil}
  @supported_types [:str, :enum, :num, :int, :bool, :port, :host, :uri]
  @required_opts [:type]

  @doc ~S"""
      iex> Mahaul.Constants.error_tuple()
      {:error, nil}
  """
  def error_tuple, do: @error_tuple

  @doc ~S"""
      iex> Mahaul.Constants.supported_types()
      [:str, :enum, :num, :int, :bool, :port, :host, :uri]
  """
  def supported_types, do: @supported_types

  @doc ~S"""
      iex> Mahaul.Constants.required_opts()
      [:type]
  """
  def required_opts, do: @required_opts

  @doc ~S"""
      iex> Mahaul.Constants.mix_env()
      :prod
  """
  def mix_env, do: Application.get_env(:mahaul, :mix_env, :prod)
end
