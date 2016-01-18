ExUnit.start()

defmodule Happy.Test do
  use ExUnit.Case

  def assert_expands_to(a, b, env) do
    Macro.expand_once(a, env)
    |> case do
      ^b -> assert(a)
      ^a -> flunk("Expected\n#{Macro.to_string(a)}\n\nto expand to\n#{Macro.to_string(b)}")
       x -> assert_expands_to(x, b, env)
    end
  end
end
