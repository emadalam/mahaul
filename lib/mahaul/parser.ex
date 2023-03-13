defmodule Mahaul.Parser do
  @moduledoc """
  Module for parsing string to supported environment variables.
  """

  alias Mahaul.Constants

  @error_tuple Constants.error_tuple()

  @doc ~S"""
  Parses a string value into one of the supported types.

  Given a string value and the supported type configuration,
  the method tries to parse the string into the provided type.
  A success tuple is returned if parsing was successful,
  otherwise an error tuple is returned.

  #### :str

      iex> Mahaul.Parser.parse("some value", :str)
      {:ok, "some value"}

  #### :enum

      iex> Mahaul.Parser.parse("atom", :enum)
      {:ok, :atom}

      iex> Mahaul.Parser.parse("value", :enum)
      {:ok, :value}

  #### :num

      iex> Mahaul.Parser.parse("10", :num)
      {:ok, 10.0}

      iex> Mahaul.Parser.parse("10.2345", :num)
      {:ok, 10.2345}

      iex> Mahaul.Parser.parse("some value", :num)
      {:error, nil}

  #### :int

      iex> Mahaul.Parser.parse("10", :int)
      {:ok, 10}

      iex> Mahaul.Parser.parse("10.2345", :int)
      {:error, nil}

      iex> Mahaul.Parser.parse("some value", :int)
      {:error, nil}

  #### :bool

      iex> Mahaul.Parser.parse(true, :bool)
      {:ok, true}

      iex> Mahaul.Parser.parse(false, :bool)
      {:ok, false}

      iex> Mahaul.Parser.parse("true", :bool)
      {:ok, true}

      iex> Mahaul.Parser.parse("false", :bool)
      {:ok, false}

      iex> Mahaul.Parser.parse("1", :bool)
      {:ok, true}

      iex> Mahaul.Parser.parse("0", :bool)
      {:ok, false}

  #### :port

      iex> Mahaul.Parser.parse("1", :port)
      {:ok, 1}

      iex> Mahaul.Parser.parse("65535", :port)
      {:ok, 65535}

      iex> Mahaul.Parser.parse("8080", :port)
      {:ok, 8080}

      iex> Mahaul.Parser.parse("some value", :port)
      {:error, nil}

      iex> Mahaul.Parser.parse("-1", :port)
      {:error, nil}

      iex> Mahaul.Parser.parse("0", :port)
      {:error, nil}

      iex> Mahaul.Parser.parse("65536", :port)
      {:error, nil}

  #### :host

      iex> Mahaul.Parser.parse("//localhost", :host)
      {:ok, "//localhost"}

      iex> Mahaul.Parser.parse("//domain.com", :host)
      {:ok, "//domain.com"}

      iex> Mahaul.Parser.parse("//192.168.0.1", :host)
      {:ok, "//192.168.0.1"}

      iex> Mahaul.Parser.parse("ftp://localhost", :host)
      {:error, nil}

      iex> Mahaul.Parser.parse("https://domain.com", :host)
      {:error, nil}

      iex> Mahaul.Parser.parse("https", :host)
      {:error, nil}

      iex> Mahaul.Parser.parse("https://domain.com/something", :host)
      {:error, nil}

  #### :uri

      iex> Mahaul.Parser.parse("ftp://localhost", :uri)
      {:ok, "ftp://localhost"}

      iex> Mahaul.Parser.parse("https://domain.com", :uri)
      {:ok, "https://domain.com"}

      iex> Mahaul.Parser.parse("postgresql://user:pass@localhost:5432/dev_db", :uri)
      {:ok, "postgresql://user:pass@localhost:5432/dev_db"}

      iex> Mahaul.Parser.parse("//localhost", :uri)
      {:error, nil}

      iex> Mahaul.Parser.parse("//domain.com", :uri)
      {:error, nil}

      iex> Mahaul.Parser.parse("//192.168.0.1", :uri)
      {:error, nil}
  """
  @spec parse(binary, Constants.var_type()) :: Constants.error_type() | Constants.success_type()
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
