defmodule Happy do

  @unhappy (quote do
    x -> x
  end)

  defmacro happy([do: block = {:__block__, _, xs = [a, b | c]}]) do
    if Enum.any?(xs, &pattern_match?/1) do
      happy_path(a, b, c, unhappy_path)
    else
      block
    end
  end

  defmacro happy([do: expr]), do: expr

  defp happy_path(a, [], _u), do: a
  defp happy_path(a, [b | xs], u), do: happy_path(a, b, xs, u)

  defp happy_path(a = {:=, _, [_, _]}, b, xs, u) do
    quote do
      cond do
        unquote(a) -> unquote(b)
      end
    end |> happy_form |> happy_path(xs, u)
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
    end |> happy_form |> happy_path(xs, u)
  end

  defp happy_path({:cond, [happy: true], [[do: [{:->, _, [[pat], expr]}]]]},
      b, xs, u) do
    quote do
      cond do
        unquote(pat) ->
           unquote(expr)
           unquote(b)
      end
    end |> happy_form |> happy_path(xs, u)
  end

  defp happy_path(a, b, xs, u) do
    quote do
      unquote(a)
      unquote(b)
    end |> happy_form |> happy_path(xs, u)
  end

  defp happy_form({a, b, c}, happy \\ true) do
    {a, [happy: happy] ++ b, c}
  end

  defp unhappy_path do
    quote do
      case do
        unquote(@unhappy)
      end
    end |> happy_form(false)
  end

  defp pattern_match?({:=, _, [_, _]}), do: true
  defp pattern_match?(_), do: false


end
