defmodule Mahaul.Configs do
  @moduledoc """
  Module for dealing with the configuration options for initialization.
  """

  alias Mahaul.Constants

  @required_opts Constants.required_opts()
  @supported_types Constants.supported_types()

  @doc """
  Validates the initialization options.

  The options keyword list is validated for any missing or invalid
  configuration option. The method throws `ArgumentError` for any
  misconfigured option.
  """
  @spec validate_opts!(keyword()) :: :ok
  def validate_opts!(opts) do
    validate_keyword!(opts)

    Enum.each(opts, fn {env_var, opt} ->
      validate_keyword!(opt, env_var)
      validate_required_opt!(opt, env_var)
      Enum.each(opt, &validate_opt!(&1, env_var))
    end)
  end

  defp validate_required_opt!(opt, name) do
    missing_opts = @required_opts -- Keyword.keys(opt)

    unless missing_opts == [] do
      raise ArgumentError, "#{name}: missing required options #{inspect(missing_opts)}"
    end
  end

  defp validate_opt!({:type, type}, name) do
    unless type in @supported_types do
      raise ArgumentError,
            "#{name}: expected :type to be one of #{inspect(@supported_types)}, got: #{inspect(type)}"
    end
  end

  defp validate_opt!({:choices, choices}, name) do
    unless is_list(choices) and not Enum.empty?(choices) do
      raise ArgumentError,
            "#{name}: expected :choices to be a non-empty list, got: #{inspect(choices)}"
    end
  end

  defp validate_opt!({:default, default}, name) do
    unless is_binary(default) do
      raise ArgumentError,
            "#{name}: expected :default to be a string, got: #{inspect(default)}"
    end
  end

  defp validate_opt!({:default_dev, default_dev}, name) do
    IO.warn(
      ~s(#{name}: :default_dev option is deprecated, use :defaults instead. eg: defaults: [prod: "MY_VAL1", dev: "MY_VAL2", test: "MY_VAL3"]),
      Macro.Env.stacktrace(__ENV__)
    )

    unless is_binary(default_dev) do
      raise ArgumentError,
            "#{name}: expected :default_dev to be a string, got: #{inspect(default_dev)}"
    end
  end

  defp validate_opt!({:defaults, defaults}, name) do
    validate_keyword!(defaults, name, ":defaults")

    Enum.each(defaults, fn {key, val} ->
      unless is_binary(val) do
        raise ArgumentError,
              "#{name}: expected :defaults :#{key} to be a string, got: #{inspect(val)}"
      end
    end)
  end

  defp validate_opt!(option, name) do
    raise ArgumentError, "#{name}: unknown option provided #{inspect(option)}"
  end

  defp validate_keyword!(opts, name \\ "Mahaul", opt_name \\ "options") do
    unless Keyword.keyword?(opts) and not Enum.empty?(opts) do
      raise ArgumentError,
            "#{name}: expected #{opt_name} to be a non-empty keyword list, got: #{inspect(opts)}"
    end
  end
end
