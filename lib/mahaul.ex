defmodule Mahaul do
  @external_resource "README.md"
  @moduledoc File.read!("README.md") |> String.replace("# Mahaul\n\n", "", global: false)

  @version "0.6.0"

  @doc false
  def version, do: @version

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      require Logger
      alias Mahaul.Helpers

      @after_compile Mahaul

      @doc false
      def __opts__, do: unquote(opts)

      Enum.each(opts, fn {key, val} ->
        str_key = Atom.to_string(key)
        fn_name = str_key |> String.downcase() |> String.to_atom()

        type = if Keyword.keyword?(val), do: val[:type]
        doc = if Keyword.keyword?(val), do: val[:doc]

        @doc if is_binary(doc),
               do: doc,
               else: "`#{key}` system environment variable value parsed as `:#{type}`."
        def unquote(fn_name)() do
          Helpers.get_env(unquote(key), unquote(val))
        end
      end)

      @doc ~s"""
      Same as `validate/0` except that it raises exception if the required
      environment variables are not set or are invalid.
      """
      def validate! do
        Logger.info("#{__MODULE__}: validating environment variables...")
        Helpers.validate!(Helpers.parse_all(unquote(opts)))
        Logger.info("#{__MODULE__}: environment variables ok")
      end

      @doc ~s"""
      Validates all currently set environment variables against the app required
      environment variables. Return {:ok} if all required environment variables
      are present and can be parsed as per the given configurations. It otherwise
      return {:error, error_string} with the list of errors.
      """
      def validate do
        Helpers.validate(Helpers.parse_all(unquote(opts)))
      end
    end
  end

  alias Mahaul.Helpers

  @doc false
  defmacro __after_compile__(%{module: module}, _env) do
    Helpers.validate_opts!(module.__opts__())
  end
end
