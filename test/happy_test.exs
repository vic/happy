defmodule HappyTest do
  use ExUnit.Case
  import Happy.Test
  import Happy

  doctest Happy

  test "empty block expands to itself" do
    a = quote do
      happy_path do
      end
    end
    b = quote do
    end
    assert_expands_to a, b, __ENV__
  end

  test "single block expands to itself" do
    a = quote do
      happy_path do
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
      happy_path do
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
      happy_path do
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
      happy_path do
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
      happy_path do
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

  test "block with match and expr expands to case" do
    a = quote do
      happy_path do
        foo = bar
        foo + 1
      end
    end
    b = quote do
      case(bar) do
        foo -> foo + 1
      end
    end
    assert_expands_to a, b, __ENV__
  end

  test "block with match and two exprs expands to case" do
    a = quote do
      happy_path do
        foo = bar
        baz
        bat
      end
    end
    b = quote do
      case(bar) do
        foo ->
          baz
          bat
      end
    end
    assert_expands_to a, b, __ENV__
  end

  test "block with match and three exprs expands to case" do
    a = quote do
      happy_path do
        foo = bar
        baz
        bat
        moo
      end
    end
    b = quote do
      case(bar) do
        foo ->
          baz
          bat
          moo
      end
    end
    assert_expands_to a, b, __ENV__
  end

  test "block with match exprs and other match expands to nested case" do
    a = quote do
      happy_path do
        foo = bar
        baz
        bat = man
        moo
      end
    end
    b = quote do
      case(bar) do
        foo ->
          baz
          case(man) do
            bat -> moo
          end
      end
    end
    assert_expands_to a, b, __ENV__
  end

  test "single block with else expands to itself" do
    a = quote do
      happy_path do
        foo
      else
        :true -> :unhappy
      end
    end
    b = quote do
      foo
    end
    assert_expands_to a, b, __ENV__
  end

  test "happy with else block, match and expr expands to case" do
    a = quote do
      happy_path do
        foo = bar
        foo + 1
      else
        :unhappy -> bar
      end
    end
    b = quote do
      case(bar) do
        foo -> foo + 1
        :unhappy -> bar
      end
    end
    assert_expands_to a, b, __ENV__
  end

  test "happy block with multiple pattern matching" do
    a = quote do
      happy_path do
        c = b = a
        e
      end
    end
    b = quote do
      case(a) do
        c = b -> e
      end
    end
    assert_expands_to a, b, __ENV__
  end

  test "two consecutive match expressions compile to nested case" do
    a = quote do
      happy_path do
        b = a
        c = b
        d
      end
    end
    b = quote do
      case(a) do
        b ->
          case(b) do
            c -> d
          end
      end
    end
    assert_expands_to a, b, __ENV__
  end

end
