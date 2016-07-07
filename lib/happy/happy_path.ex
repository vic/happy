defmodule Happy.HappyPath do

  @happy (quote do
             {:happy, x} -> x
           end)

  @default (quote do
             x -> x
            end)

  defmacro __using__(_) do
    quote do
      defmacro happy_path!(opts) do
        Happy.HappyPath.happy_macro!(opts)
      end

      defmacro happy_path(opts) do
        Happy.HappyPath.happy_macro(opts)
      end

      defmacro happy_path(opts, blocks) do
        Happy.HappyPath.happy_opts(opts, blocks)
        |> Happy.HappyPath.happy_macro
      end

      defmacro happy_path!(opts, blocks) do
        Happy.HappyPath.happy_opts(opts, blocks)
        |> Happy.HappyPath.happy_macro!
      end
    end
  end

  #### macurosu

  def happy_macro!([do: path = {:__block__, _, _}]) do
    happy_path!(path)
  end

  def happy_macro!([do: x]), do: x

  def happy_macro!([do: path = {:__block__, _, _},
                          else: unhappy = [{:->, _, _} | _]]) do
    happy_path!(path, unhappy)
  end

  def happy_macro!([do: x, else: [{:->, _, _} | _]]), do: x

  def happy_macro([do: path = {:__block__, _, _}]) do
    happy_path(path)
  end

  def happy_macro([do: x]), do: x

  def happy_macro([do: path = {:__block__, _, _},
                         else: unhappy = [{:->, _, _} | _]]) do
    happy_path(path, unhappy)
  end

  def happy_macro([do: x, else: [{:->, _, _} | _]]), do: x

  def happy_opts([else: else_pipe], blocks) do
    else_clauses = Keyword.get(blocks, :else, []) ++ quote do
      x -> x |> unquote(else_pipe)
    end
    Keyword.delete(blocks, :else) ++ [else: else_clauses]
  end

  ####


  defp happy_path!(path) do
    make_happy(path, @happy)
  end

  defp happy_path!(path, unhappy) do
    make_happy(path, @happy ++ unhappy)
  end

  defp happy_path(path) do
    make_happy(path, @happy ++ @default)
  end

  defp happy_path(path, unhappy) do
    make_happy(path, @happy ++ unhappy)
  end

  defp make_happy({:__block__, l, path}, unhappy) do
    if can_be_happier?(path) do
      happier(path) |> unhappy_path(unhappy)
    else
      expr = path |> Stream.map(&happy_match/1) |> Enum.map(&skipped/1)
      {:__block__, l, expr}
    end
  end

  defp skipped({:skip, skipped}) do
    skipped
  end

  defp can_be_happier?(xs) do
    Enum.any?(xs, &happy_match?/1)
  end

  defp happier(xs) do
    xs
    |> Stream.map(&happy_match/1)
    |> Enum.reverse
    |> Enum.reduce(nil, &happy_expand/2)
  end

  defp happy_match?(expr) do
    case happy_match(expr) do
      {:skip, _} -> false
      _ -> true
    end
  end

  defp happy_match({:@, _, [{:happy, _, [skipped = {:=, _, _}]}]}) do
    {:skip, skipped}
  end

  defp happy_match({:@, _, [{tag, _, [b = {:when, _, _}]}]}) do
    {:ok, {:when, _, [a, w]}, e} = happy_match(b)
    {:ok, {:when, [], [{tag, a}, w]}, {tag, e}}
  end

  defp happy_match({:@, _, [{tag, _, [b]}]}) do
    {:ok, p, e} = happy_match_eq(b)
    {:ok, {tag, p}, {tag, e}}
  end

  defp happy_match({:when, _, [a, b]}) do
    {:ok, w, e} = happy_match_eq(b)
    {:ok, {:when, [], [a, w]}, e}
  end

  defp happy_match({:=, _, [a, b = {:=, _, _}]}) do
    {:ok, p, e} = happy_match_eq(b)
    {:ok, {:=, [], [a, p]}, e}
  end

  defp happy_match(no_pattern_match = {:=, _, [{x, _, y}, _]}) when is_atom(x) and is_atom(y) do
    {:skip, no_pattern_match}
  end

  defp happy_match(eq = {:=, _, _}) do
    happy_match_eq(eq)
  end

  defp happy_match(expression), do: {:skip, expression}

  defp happy_match_eq({:=, _, [pattern, expression]}) do
    {:ok, pattern, expression}
  end

  defp happy_form({a, _, c}) do
    {a, [happy: true], c}
  end

  defp happy_expand({:ok, pattern, expression}, nil) do
    {:=, [], [pattern, expression]}
  end

  defp happy_expand({:ok, pattern, expression}, v) do
    quote do
      unquote(expression) |> case do
        unquote(pattern) -> unquote(v)
        x -> x
      end
    end |> happy_form
  end

  defp happy_expand({:skip, final_expression}, nil) do
    {:happy, final_expression}
  end

  defp happy_expand({:skip, a}, {:__block__, m, b}) do
    {:__block__, m, [a] ++ b}
  end

  defp happy_expand({:skip, a}, b) do
    block = {:__block__, [], [a, b]}
    case b do
      {_, [happy: true], _} -> block |> happy_form
      _ -> block
    end
  end

  defp unhappy_path(happy = {_, [happy: true], _}, unhappy) do
    {:|>, [], [happy, unhappy_case(unhappy)]}
  end

  defp unhappy_path(x, _), do: x

  defp unhappy_case(unhappy_cases) do
    {:case, [], [[do: unhappy_cases]]}
  end

end
