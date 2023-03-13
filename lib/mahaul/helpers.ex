defmodule Mahaul.Helpers do
  @moduledoc """
  Basic helpers for parsing and validating the system environment variables.
  """

  require Logger
  alias Mahaul.{Configs, Constants, Env}

  @error_tuple Constants.error_tuple()

  @doc """
  Returns a list of parsed environment variable values.

  See `Mahaul.Env.get_all_normalized_values/1`.
  """
  @spec parse_all(Constants.config_type()) :: Constants.normalized_values_type()
  def parse_all(opts), do: Env.get_all_normalized_values(opts)

  @doc """
  Returns a valid parsed environment variable value or `nil`.
  """
  @spec get_env(atom, keyword) :: Constants.value_type()
  def get_env(key, config), do: elem(Env.get_env(key, config), 1)

  @doc """
  Validates the initialization options.

  See `Mahaul.Configs.validate_opts!/1`.
  """
  @spec validate_opts!(keyword()) :: :ok
  def validate_opts!(opts), do: Configs.validate_opts!(opts)

  @doc """
  Validates and throws error for invalid environment variables.

  Same as `validate/1`, except that it raises exception on error.
  """
  @spec validate!(Constants.normalized_values_type()) :: nil
  def validate!(parsed_envs) do
    case validate(parsed_envs) do
      {:ok} -> nil
      {:error, _errors} -> raise "Invalid environment variables!"
    end
  end

  @doc """
  Validates the list of parsed environment variables.

  Given a list of parsed environment variables, the method validates
  the list to contain all valid environment variables. For any invalid
  values, the method logs the name of the missing environment variable
  and returns the list of errors.
  """
  @spec validate(Constants.normalized_values_type()) :: {:ok} | {:error, binary}
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
end
