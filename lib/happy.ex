defmodule Happy do

  defmacro happy([do: block = {:__block__, l, xs = [a, b | c]}]) do
    if Enum.any?(xs, &pattern_match?/1) do
      happy_path(a, b, c)
    else
      block
    end
  end

  defmacro happy([do: expr]), do: expr

  defp happy_path(a, []), do: a
  defp happy_path(a, [b | xs]), do: happy_path(a, b, xs)

  defp happy_path(a = {:=, _, [_, _]}, b, xs) do
    quote do
      cond do
        unquote(a) -> unquote(b)
      end
    end |> happy_path(xs)
  end

  defp happy_path(a = {:cond, [], _}, b = {:=, _, [_, _]}, xs) do
    happy_path(a, [happy_path(b, xs)])
  end

  defp happy_path(a =
        {:cond, [], [[do: [{:->, [], [[pat], {:__block__, [], ax}]}]]]},
      b, xs) do
    quote do
      cond do
        unquote(pat) ->
          unquote_splicing(ax)
          unquote(b)
      end
    end |> happy_path(xs)
  end

  defp happy_path(a =
        {:cond, [], [[do: [{:->, [], [[pat], expr]}]]]},
      b, xs) do
    quote do
      cond do
        unquote(pat) ->
           unquote(expr)
           unquote(b)
      end
    end |> happy_path(xs)
  end

  defp happy_path(a, b, xs) do
    quote do
      unquote(a)
      unquote(b)
    end |> happy_path(xs)
  end

  defp pattern_match?({:=, _, [_, _]}), do: true
  defp pattern_match?(_), do: false

end
