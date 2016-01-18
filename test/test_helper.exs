ExUnit.start()

defmodule Happy.Test do
  use ExUnit.Case

  def assert_expands_to(a, b, env) do
    as = Macro.to_string(a)
    bs = Macro.to_string(b)

    x  = Macro.expand_once(a, env)
    xs = Macro.to_string(x)

    cond do
      xs == bs -> assert(a)
      xs == as ->
        flunk("""
        Expected

        #{Macro.to_string(a)}

        to expand into

        #{Macro.to_string(b)}
        """)
      :else ->
        assert_expands_to(x, b, env)
    end
  end

end
