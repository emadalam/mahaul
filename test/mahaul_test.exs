defmodule MahaulTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  @env_list [
    {"MOCK__ENV__STR", "__MOCK__VAL1__"},
    {"MOCK__ENV__ENUM", "__MOCK__VAL2__"},
    {"MOCK__ENV__NUM", "10.10"},
    {"MOCK__ENV__INT", "10"},
    {"MOCK__ENV__BOOL", "true"},
    {"MOCK__ENV__PORT", "8080"},
    {"MOCK__ENV__HOST", "//example.com"},
    {"MOCK__ENV__URI", "https://example.com/something"}
  ]

  setup do
    System.put_env(@env_list)

    on_exit(fn ->
      @env_list |> Enum.each(fn {key, _} -> System.delete_env(key) end)
    end)
  end

  describe "validate/0" do
    test "should return success for valid environment variables" do
      defmodule Env1 do
        use Mahaul,
          MOCK__ENV__STR: [type: :str],
          MOCK__ENV__ENUM: [type: :enum],
          MOCK__ENV__NUM: [type: :num],
          MOCK__ENV__INT: [type: :int],
          MOCK__ENV__BOOL: [type: :bool],
          MOCK__ENV__PORT: [type: :port],
          MOCK__ENV__HOST: [type: :host],
          MOCK__ENV__URI: [type: :uri]
      end

      assert {:ok} = Env1.validate()
    end

    test "should return error for all invalid environment variables" do
      defmodule Env2 do
        use Mahaul,
          MOCK__ENV__MISSING: [type: :str],
          MOCK__ENV__NUM: [type: :int],
          MOCK__ENV__INT: [type: :bool],
          MOCK__ENV__BOOL: [type: :num],
          MOCK__ENV__PORT: [type: :host],
          MOCK__ENV__HOST: [type: :uri],
          MOCK__ENV__URI: [type: :int]
      end

      fun = fn ->
        assert {:error,
                "MOCK__ENV__MISSING\nMOCK__ENV__NUM\nMOCK__ENV__INT\nMOCK__ENV__BOOL\nMOCK__ENV__PORT\nMOCK__ENV__HOST\nMOCK__ENV__URI"} =
                 Env2.validate()
      end

      capture_log(fun) =~ ~s(missing or invalid environment variables.
      MOCK__ENV__MISSING
      MOCK__ENV__NUM
      MOCK__ENV__INT
      MOCK__ENV__BOOL
      MOCK__ENV__PORT
      MOCK__ENV__HOST
      MOCK__ENV__URI)
    end
  end

  describe "validate!/0" do
    test "should not raise exception for valid environment variables" do
      defmodule Env3 do
        use Mahaul,
          MOCK__ENV__STR: [type: :str],
          MOCK__ENV__ENUM: [type: :enum],
          MOCK__ENV__NUM: [type: :num],
          MOCK__ENV__INT: [type: :int],
          MOCK__ENV__BOOL: [type: :bool],
          MOCK__ENV__PORT: [type: :port],
          MOCK__ENV__HOST: [type: :host],
          MOCK__ENV__URI: [type: :uri]
      end

      fun = fn ->
        assert :ok = Env3.validate!()
      end

      capture_log(fun)
    end

    test "should raise exception for invalid environment variables" do
      defmodule Env4 do
        use Mahaul,
          MOCK__ENV__MISSING: [type: :str],
          MOCK__ENV__NUM: [type: :int],
          MOCK__ENV__INT: [type: :bool],
          MOCK__ENV__BOOL: [type: :num],
          MOCK__ENV__PORT: [type: :host],
          MOCK__ENV__HOST: [type: :uri],
          MOCK__ENV__URI: [type: :int]
      end

      fun = fn ->
        assert_raise RuntimeError, "Invalid environment variables!", fn ->
          Env4.validate!()
        end
      end

      capture_log(fun) =~ ~s(missing or invalid environment variables.
      MOCK__ENV__MISSING
      MOCK__ENV__NUM
      MOCK__ENV__INT
      MOCK__ENV__BOOL
      MOCK__ENV__PORT
      MOCK__ENV__HOST
      MOCK__ENV__URI)
    end
  end

  describe "accessing environment variables" do
    test "should work" do
      defmodule Env5 do
        use Mahaul,
          MOCK__ENV__STR: [type: :str],
          MOCK__ENV__ENUM: [type: :enum],
          MOCK__ENV__NUM: [type: :num],
          MOCK__ENV__INT: [type: :int],
          MOCK__ENV__BOOL: [type: :bool],
          MOCK__ENV__PORT: [type: :port],
          MOCK__ENV__HOST: [type: :host],
          MOCK__ENV__URI: [type: :uri]
      end

      assert "__MOCK__VAL1__" = Env5.mock__env__str()
      assert :__MOCK__VAL2__ = Env5.mock__env__enum()
      assert 10.10 = Env5.mock__env__num()
      assert 10 = Env5.mock__env__int()
      assert true = Env5.mock__env__bool()
      assert 8080 = Env5.mock__env__port()
      assert "//example.com" = Env5.mock__env__host()
      assert "https://example.com/something" = Env5.mock__env__uri()
    end
  end
end
