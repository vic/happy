defmodule Happy.HappyPipe do

  defmacro __using__(:happy_pipe) do
    quote do
      defmacro happy(x) do
        Happy.HappyPipe.happy(x)
      end
    end
  end

  def happy(x) do
    Happy.Macro.piped(x)
    |> Macro.unpipe
    |> Stream.map(fn {q, 0} -> q end)
    |> Enum.reverse
    |> make_happy([])
    |> apply_happy
  end

  defp apply_happy([a]), do: a
  defp apply_happy([a, hfn | rest]) do
    apply_happy([hfn.(a) | rest])
  end

  defp make_happy([a], res) do
    [a] ++ res
  end

  defp make_happy([b, a], res) do
    x = pipe_fn(b)
    make_happy([a], [x] ++ res)
  end

  defp make_happy([c, {happy, _, [b | _]} | prev], res)
  when (happy == :happy or happy == :unhappy) do
    x = pipe_if(happy, b, c)
    make_happy(prev, [x] ++ res)
  end

  defp make_happy([c, b | prev], res) do
    x = pipe_fn(b, c)
    make_happy(prev, [x] ++ res)
  end

  defp pipe_fn(b) do
    fn a ->
      quote do
        unquote(a) |> unquote(b)
      end
    end
  end

  defp pipe_fn(b, c) do
    fn a ->
      quote do
        unquote(a) |> unquote(b) |> unquote(c)
      end
    end
  end

  def pipe_if(happy, b, c) do
    hif = happy == :happy && :if || :unless
    fn a ->
      quote do
        happy_value = unquote(a)
        unquote(hif)(match?(unquote(b), happy_value)) do
          happy_value |> unquote(c)
        else
          happy_value
        end
      end
    end
  end

end
