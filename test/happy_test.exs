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

  test "block with expr and match expands to itself" do
    a = quote do
      happy do
        baz
        foo = baz
      end
    end
    b = quote do
      baz
      foo = baz
    end
    assert_expands_to a, b, __ENV__
  end


  test "block with elixir cond expands to itself" do
    a = quote do
      happy do
        cond do
          true -> nil
        end
        foo
      end
    end
    b = quote do
      cond do
        true -> nil
      end
      foo
    end
    assert_expands_to a, b, __ENV__
  end

  test "block with match and expr expands to cond" do
    a = quote do
      happy do
        foo = bar
        foo
      end
    end
    b = quote do
      cond do
        foo = bar -> foo
        :else -> :error
      end
    end
    assert_expands_to a, b, __ENV__
  end

  test "block with match and two exprs expands to cond" do
    a = quote do
      happy do
        foo = bar
        baz
        bat
      end
    end
    b = quote do
      cond do
        foo = bar -> baz
          bat
        :else -> :error
      end
    end
    assert_expands_to a, b, __ENV__
  end

  test "block with match and three exprs expands to cond" do
    a = quote do
      happy do
        foo = bar
        baz
        bat
        moo
      end
    end
    b = quote do
      cond do
        foo = bar -> baz
          bat
          moo
        :else -> :error
      end
    end
    assert_expands_to a, b, __ENV__
  end

  test "block with match exprs and other match expands to nested cond" do
    a = quote do
      happy do
        foo = bar
        baz
        bat = man
        moo
      end
    end
    b = quote do
      cond do
        foo = bar -> baz
          cond do
            bat = man -> moo
            :else -> :error
          end
        :else -> :error
      end
    end
    assert_expands_to a, b, __ENV__
  end

end
