defmodule Happy do

  @moduledoc """
  Happy path programming in elixir.
  """

  # happy block with at least two expressions
  # using custom unhappy path
  @doc false
  defmacro happy_path([do: block = {:__block__, _, xs = [a, b | c]},
                  else: unhappy]) do
    if Enum.any?(xs, &pattern_match?/1) do
      make_happy(a, b, c, unhappy)
    else
      block
    end
  end

  # happy block with at least two expressions
  # using default unhappy path
  @doc false
  defmacro happy_path([do: block = {:__block__, _, xs = [a, b | c]}]) do
    if Enum.any?(xs, &pattern_match?/1) do
      make_happy(a, b, c, [])
    else
      block
    end
  end

  @doc false
  defmacro happy_path([do: expr, else: _]), do: expr
  @doc false
  defmacro happy_path([do: expr]), do: expr

  # append unhappy path to case when no more expressions remain
  defp make_happy({:case, m = [happy_path: true], [e, [do: xs]]}, [], unhappy) do
    {:case, m, [e, [do: xs ++ unhappy]]}
  end

  defp make_happy(a, [], _u), do: a
  defp make_happy(a, [b | xs], u), do: make_happy(a, b, xs, u)


  # create nested case expression when two consecutive match found
  defp make_happy(a = {:=, _, _}, b = {:=, _, _}, xs = [_ | _], u) do
    make_happy(a,  [make_happy(b, xs, u)], u)
  end

  # create a case expression from a to b and continue with rest expressions
  defp make_happy(a = {:=, _, _}, b, xs, u) do
    happy_case(a, b, xs, u)
  end

  defp make_happy(a = {:@, _, [{_, _, [{:=, _, _}]}]}, b, xs, u) do
    happy_case(a, b, xs, u)
  end

  defp make_happy(a = {:@, _, [{_, _, [{:when, _, _}]}]}, b, xs, u) do
    happy_case(a, b, xs, u)
  end

  #
  defp make_happy(a = {:when, _, [_, {:=, _, _}]}, b, xs, u) do
    happy_case(a, b, xs, u)
  end

  # create another nested case when another pattern matching found in chain
  defp make_happy(a = {:case, [happy_path: true], _}, b = {:=, _, _}, xs, u) do
    make_happy(a,  [make_happy(b, xs, u)], u)
  end

  # append `b` expression to current block case(p -> ax)
  defp make_happy({:case, [happy_path: true],
                    [e, [do: [{:->, _, [[p], {:__block__, _, ax}]}]]]},
      b, xs, u) do
    happy_append(e, p, ax, b, xs, u)
  end

  # create a block by appending `b` expression to current case(p -> a)
  defp make_happy({:case, [happy_path: true], [e, [do: [{:->, _, [[p], a]}]]]},
      b, xs, u) do
    happy_append(e, p, [a], b, xs, u)
  end

  # create a block with `a` and `b` and continue with chain
  defp make_happy(a, b, xs, u) do
    quote do
      unquote(a)
      unquote(b)
    end |> make_happy(xs, u)
  end

  # create a happy case
  defp happy_case(a, b, xs, u) do
    {e, p} = pattern_match(a)
    quote do
      case(unquote(e)) do
        unquote(p) -> unquote(b)
      end
    end |> happy_form |> make_happy(xs, u)
  end

  defp happy_append(e, p, ax, b, xs, u) do
    quote do
      case(unquote(e)) do
        unquote(p) ->
          unquote_splicing(ax)
          unquote(b)
      end
    end |> happy_form |> make_happy(xs, u)
  end

  # mark a form with happy metadata
  defp happy_form({x, m, y}) do
    {x, [happy_path: true] ++ m, y}
  end

  # is the given form a pattern match?
  defp pattern_match?({:@, _, [{_, _, [{:=, _, [_, _]}]}]}), do: true
  defp pattern_match?({:@, _, [{_, _, [{:when, _, _}]}]}), do: true
  defp pattern_match?({:when, _, [_, {:=, _, [_, _]}]}), do: true
  defp pattern_match?({:=, _, [_, _]}), do: true
  defp pattern_match?(_), do: false

  defp pattern_match({:@, _, [{t, _, [x = {:when, _, _}]}]}) do
    {e, {:when, l, [p, w]}} = pattern_match(x)
    {{t, e}, {:when, l, [{t,p}, w]}}
  end

  defp pattern_match({:@, _, [{t, _, [x = {:=, _, _}]}]}) do
    {e, p} = pattern_match(x)
    {{t, e}, {t, p}}
  end

  # a when b = c
  defp pattern_match({:when, l, [p, eq = {:=, _, _}]}) do
    {e, w} = pattern_match(eq)
    {e, {:when, l, [p, w]}}
  end

  # a = b = c
  defp pattern_match({:=, l, [a, {:=, m, [b, c]}]}) do
    pattern_match({:=, l, [{:=, m, [a, b]}, c]})
  end

  defp pattern_match({:=, _, [p, e]}), do: {e, p}


end
