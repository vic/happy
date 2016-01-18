defmodule HappyTest do
  use ExUnit.Case
  import Happy.Test
  import Happy

  doctest Happy

  test "empty block expands to itself" do
    a = quote do
      happy do
      end
    end
    b = quote do
    end
    assert_expands_to a, b, __ENV__
  end

  test "single block expands to itself" do
    a = quote do
      happy do
        foo
      end
    end
    b = quote do
      foo
    end
    assert_expands_to a, b, __ENV__
  end

  test "block without matches expands to itself" do
    a = quote do
      happy do
        foo
        bar
      end
    end
    b = quote do
      foo
      bar
    end
    assert_expands_to a, b, __ENV__
  end

  test "block with single match expands to itself" do
    a = quote do
      happy do
        foo = bar
      end
    end
    b = quote do
      foo = bar
    end
    assert_expands_to a, b, __ENV__
  end

  test "block wit match and expr expands to cond" do
    a = quote do
      happy do
        foo = bar
        baz
      end
    end
    b = quote do
      cond do
        foo = bar -> baz
      end
    end
    assert_expands_to a, b, __ENV__
  end


end
