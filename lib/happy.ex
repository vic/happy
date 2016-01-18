defmodule Happy do

  @unhappy (quote do
    :else -> :error
  end)

  defmacro happy([do: block = {:__block__, _, xs = [a, b | c]}]) do
    if Enum.any?(xs, &pattern_match?/1) do
      happy_path(a, b, c, @unhappy)
    else
      block
    end
  end

  defmacro happy([do: expr]), do: expr

  defp happy_path({:cond, m = [happy: true], [[do: xs]]}, [], unhappy) do
    {:cond, m, [[do: xs ++ unhappy]]}
  end

  defp happy_path(a, [], _u), do: a
  defp happy_path(a, [b | xs], u), do: happy_path(a, b, xs, u)

  defp happy_path(a = {:=, _, [_, _]}, b, xs, u) do
    quote do
      cond do
        unquote(a) -> unquote(b)
      end
    end |> happy_cond |> happy_path(xs, u)
  end

  defp happy_path(a = {:cond, [happy: true], _}, b = {:=, _, [_, _]}, xs, u) do
    happy_path(a, [happy_path(b, xs, u)], u)
  end

  defp happy_path({:cond, [happy: true],
                    [[do: [{:->, _, [[pat], {:__block__, _, ax}]}]]]},
      b, xs, u) do
    quote do
      cond do
        unquote(pat) ->
          unquote_splicing(ax)
          unquote(b)
      end
    end |> happy_cond |> happy_path(xs, u)
  end

  defp happy_path({:cond, [happy: true], [[do: [{:->, _, [[pat], expr]}]]]},
      b, xs, u) do
    quote do
      cond do
        unquote(pat) ->
           unquote(expr)
           unquote(b)
      end
    end |> happy_cond |> happy_path(xs, u)
  end

  defp happy_path(a, b, xs, u) do
    quote do
      unquote(a)
      unquote(b)
    end |> happy_path(xs, u)
  end

  defp happy_cond({:cond, m, n}) do
    {:cond, [happy: true] ++ m, n}
  end

  defp pattern_match?({:=, _, [_, _]}), do: true
  defp pattern_match?(_), do: false


end
