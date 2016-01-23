defmodule Happy.Path do

  @happy (quote do
             {:happy, x} -> x
           end)

  @default (quote do
             x -> x
            end)


  def happy_path!(path) do
    make_happy(path, @happy)
  end

  def happy_path!(path, unhappy) do
    make_happy(path, @happy ++ unhappy)
  end

  def happy_path(path) do
    make_happy(path, @happy ++ @default)
  end

  def happy_path(path, unhappy) do
    make_happy(path, @happy ++ unhappy)
  end

  defp make_happy({:__block__, l, path}, unhappy) do
    if can_be_happier?(path) do
      happier(path) |> unhappy_path(unhappy)
    else
      {:__block__, l, path}
    end
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
      {^expr} -> false
      _ -> true
    end
  end

  defp happy_match({:@, _, [{tag, _, [b = {:when, _, _}]}]}) do
    {{:when, _, [a, w]}, e} = happy_match(b)
    {{:when, [], [{tag, a}, w]}, {tag, e}}
  end

  defp happy_match({:@, _, [{tag, _, [b]}]}) do
    {p, e} = happy_match(b)
    {{tag, p}, {tag, e}}
  end

  defp happy_match({:when, _, [a, b]}) do
    {w, e} = happy_match(b)
    {{:when, [], [a, w]}, e}
  end

  defp happy_match({:=, _, [a, b = {:=, _, _}]}) do
    {p, e} = happy_match(b)
    {{:=, [], [a, p]}, e}
  end

  defp happy_match({:=, _, [pattern, expression]}) do
    {pattern, expression}
  end

  defp happy_match(expression), do: {expression}

  defp happy_form({a, _, c}) do
    {a, [happy: true], c}
  end

  defp happy_expand({pattern, expression}, nil) do
    {:=, [], [pattern, expression]}
  end

  defp happy_expand({pattern, expression}, v) do
    quote do
      unquote(expression) |> case do
        unquote(pattern) -> unquote(v)
        x -> x
      end
    end |> happy_form
  end

  defp happy_expand({final_expression}, nil) do
    {:happy, final_expression}
  end

  defp happy_expand({a}, {:__block__, m, b}) do
    {:__block__, m, [a] ++ b}
  end

  defp happy_expand({a}, b) do
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
