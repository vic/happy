defmodule Happy do

  @moduledoc """
  Happy path programming in elixir.
  """

  # happy block with at least two expressions
  # using custom unhappy path
  @doc false
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
  @doc false
  defmacro happy([do: block = {:__block__, _, xs = [a, b | c]}]) do
    if Enum.any?(xs, &pattern_match?/1) do
      happy_path(a, b, c, [])
    else
      block
    end
  end

  @doc false
  defmacro happy([do: expr, else: _]), do: expr
  @doc false
  defmacro happy([do: expr]), do: expr

  # append unhappy path to case when no more expressions remain
  defp happy_path({:case, m = [happy: true], [e, [do: xs]]}, [], unhappy) do
    {:case, m, [e, [do: xs ++ unhappy]]}
  end

  defp happy_path(a, [], _u), do: a
  defp happy_path(a, [b | xs], u), do: happy_path(a, b, xs, u)

  # create a case expression from a to b and continue with rest expressions
  defp happy_path(a = {:=, _, _}, b, xs, u) do
    {e, p} = pattern_match(a)
    quote do
      case(unquote(e)) do
        unquote(p) -> unquote(b)
      end
    end |> happy_form |> happy_path(xs, u)
  end

  # create another nested case when another pattern matching found in chain
  defp happy_path(a = {:case, [happy: true], _}, b = {:=, _, _}, xs, u) do
    happy_path(a, [happy_path(b, xs, u)], u)
  end

  # append `b` expression to current block case(p -> ax)
  defp happy_path({:case, [happy: true],
                    [e, [do: [{:->, _, [[p], {:__block__, _, ax}]}]]]},
      b, xs, u) do
    quote do
      case(unquote(e)) do
        unquote(p) ->
          unquote_splicing(ax)
          unquote(b)
      end
    end |> happy_form |> happy_path(xs, u)
  end

  # create a block by appending `b` expression to current case(p -> a)
  defp happy_path({:case, [happy: true], [e, [do: [{:->, _, [[p], a]}]]]},
      b, xs, u) do
    quote do
      case(unquote(e)) do
        unquote(p) ->
           unquote(a)
           unquote(b)
      end
    end |> happy_form |> happy_path(xs, u)
  end

  # create a block with `a` and `b` and continue with chain
  defp happy_path(a, b, xs, u) do
    quote do
      unquote(a)
      unquote(b)
    end |> happy_path(xs, u)
  end

  # mark a form with happy metadata
  defp happy_form({x, m, y}) do
    {x, [happy: true] ++ m, y}
  end

  # is the given form a pattern match?
  defp pattern_match?({:=, _, [_, _]}), do: true
  defp pattern_match?(_), do: false


  # a = b = c
  defp pattern_match({:=, l, [a, {:=, m, [b, c]}]}) do
    pattern_match({:=, l, [{:=, m, [a, b]}, c]})
  end
  defp pattern_match({:=, _, [a, b]}), do: {b, a}


end
