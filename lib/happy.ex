defmodule Happy do

  @unhappy (quote do
    :else -> :error
  end)

  # happy block with at least two expressions
  # using custom unhappy path
  defmacro happy([do: block = {:__block__, _, xs = [a, b | c]},
                  else: unhappy]) do
    if Enum.any?(xs, &pattern_match?/1) do
      happy_path(a, b, c, unhappy)
    else
      block
    end
  end

  # happy block with at least two expressions
  # using default unhappy path
  defmacro happy([do: block = {:__block__, _, xs = [a, b | c]}]) do
    if Enum.any?(xs, &pattern_match?/1) do
      happy_path(a, b, c, @unhappy)
    else
      block
    end
  end

  defmacro happy([do: expr, else: _]), do: expr
  defmacro happy([do: expr]), do: expr

  # append unhappy path to cond when no more expressions remain
  defp happy_path({:cond, m = [happy: true], [[do: xs]]}, [], unhappy) do
    {:cond, m, [[do: xs ++ unhappy]]}
  end

  defp happy_path(a, [], _u), do: a
  defp happy_path(a, [b | xs], u), do: happy_path(a, b, xs, u)

  # create a cond expression from a to b and continue with rest expressions
  defp happy_path(a = {:=, _, [_, _]}, b, xs, u) do
    quote do
      cond do
        unquote(a) -> unquote(b)
      end
    end |> happy_cond |> happy_path(xs, u)
  end

  # create another nested cond when another pattern matching found in chain
  defp happy_path(a = {:cond, [happy: true], _}, b = {:=, _, [_, _]}, xs, u) do
    happy_path(a, [happy_path(b, xs, u)], u)
  end

  # append `b` expression to current block cond(p -> ax)
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

  # create a block by appending `b` expression to current cond(p -> a)
  defp happy_path({:cond, [happy: true], [[do: [{:->, _, [[pat], a]}]]]},
      b, xs, u) do
    quote do
      cond do
        unquote(pat) ->
           unquote(a)
           unquote(b)
      end
    end |> happy_cond |> happy_path(xs, u)
  end

  # create a block with `a` and `b` and continue with chain
  defp happy_path(a, b, xs, u) do
    quote do
      unquote(a)
      unquote(b)
    end |> happy_path(xs, u)
  end

  # mark a cond form with happy metadata
  defp happy_cond({:cond, m, n}) do
    {:cond, [happy: true] ++ m, n}
  end

  # is the given form a pattern match?
  defp pattern_match?({:=, _, [_, _]}), do: true
  defp pattern_match?(_), do: false


end
