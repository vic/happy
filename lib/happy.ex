defmodule Happy do

  @unhappy (quote do
    _unhappy_ -> _unhappy_
  end)

  defmacro happy([do: block = {:__block__, _, xs = [a, b | c]}]) do
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
    end |> happy_form |> happy_path(xs)
  end

  defp happy_path(a = {:cond, [happy: true], _}, b = {:=, _, [_, _]}, xs) do
    happy_path(a, [happy_path(b, xs)])
  end

  defp happy_path({:cond, [happy: true],
                    [[do: [{:->, _, [[pat], {:__block__, _, ax}]}]]]},
      b, xs) do
    quote do
      cond do
        unquote(pat) ->
          unquote_splicing(ax)
          unquote(b)
      end
    end |> happy_form |> happy_path(xs)
  end

  defp happy_path({:cond, [happy: true], [[do: [{:->, _, [[pat], expr]}]]]},
      b, xs) do
    quote do
      cond do
        unquote(pat) ->
           unquote(expr)
           unquote(b)
      end
    end |> happy_form |> happy_path(xs)
  end

  defp happy_path(a, b, xs) do
    quote do
      unquote(a)
      unquote(b)
    end |> happy_form |> happy_path(xs)
  end

  defp pattern_match?({:=, _, [_, _]}), do: true
  defp pattern_match?(_), do: false

  defp happy_form({a, b, c}) do
    {a, [happy: true] ++ b, c}
  end

end
