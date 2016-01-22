ExUnit.start()

defmodule Happy.Assertions do
  use ExUnit.Case

  def assert_expands_to(a, b, env) do
    x  = Macro.expand_once(a, env)
    xs = Macro.to_string(x)
    bs = Macro.to_string(b)
    cond do
      xs == bs -> assert(a)
      :else ->
        flunk("""
        Expected

        #{Macro.to_string(a)}

        to expand into

        #{bs}

        but was

        #{xs}
        """)
    end
  end

end
