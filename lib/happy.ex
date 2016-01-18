defmodule Happy do

  defmacro happy([do: block = {:__block__, l, xs = [a, b | c]}]) do
    if Enum.any?(xs, &pattern_match?/1) do
      happy_block(a, b, c)
    else
      block
    end
  end

  defmacro happy([do: block]), do: block

  defp happy_block(a = {:=, _, [_, _]}, b, []) do
    quote do
      cond do
        unquote(a) -> unquote(b)
      end
    end
  end

  defp pattern_match?({:=, _, [_, _]}), do: true
  defp pattern_match?(_), do: false

end
