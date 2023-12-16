defmodule Mahaul.Env do
  @moduledoc """
  Module for dealing with environment variable values.
  """

  alias Mahaul.{Constants, Parser}

  @error_tuple Constants.error_tuple()

  @doc """
  Returns a list of normalized environment variable values.
  """
  @spec get_all_normalized_values(Constants.config_type()) :: Constants.normalized_values_type()
  def get_all_normalized_values(opts) do
    Enum.map(opts, &get_normalized_value/1)
  end

  @doc """
  Returns the normalized environment variable value for a given
  environment variable name and configuration option.
  """
  @spec get_normalized_value({atom, Constants.config_type()}) :: Constants.normalized_value_type()
  def get_normalized_value({key, config}) do
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

  @doc """
  Returns the parsed environment variable value.

  The type parsing is done as per the provided configuration options.
  If the default configuration option is provided and the environment
  variable is not set, the default value is parsed and returned.
  An error tuple is returned in all other cases.
  """
  @spec get_env(atom, Constants.config_type()) ::
          Constants.error_type() | Constants.success_type()
  def get_env(key, config) do
    env_name = Atom.to_string(key)
    env_type = Keyword.get(config, :type)

    env_val =
      System.get_env(env_name)
      |> maybe_decode(config)
      |> get_env_val_or_default(config)

    cond do
      env_val == @error_tuple -> @error_tuple
      is_nil(env_val) -> @error_tuple
      true -> Parser.parse(env_val, env_type)
    end
  end

  defp maybe_decode(env_val, config) when is_binary(env_val) do
    decode? = Keyword.get(config, :base64, false)

    if decode? do
      case Base.decode64(env_val) do
        {:ok, decoded} -> decoded
        :error -> @error_tuple
      end
    else
      env_val
    end
  end

  defp maybe_decode(nil, _config), do: nil

  defp get_env_val_or_default(env_val, config, mix_env \\ Constants.mix_env())
  defp get_env_val_or_default(@error_tuple, _config, _mix_env), do: @error_tuple

  defp get_env_val_or_default(env_val, config, mix_env) do
    # simplify this once we remove support for `:default_dev` option
    # in favour of the `:defaults` option
    if Keyword.has_key?(config, :default_dev) do
      case mix_env do
        env when env in [:dev, :test] ->
          env_val || Keyword.get(config, :default_dev) || Keyword.get(config, :default)

        _ ->
          env_val || Keyword.get(config, :default)
      end
    else
      env_val || config[:defaults][mix_env] || Keyword.get(config, :default)
    end
  end
end
