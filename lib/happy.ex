defmodule Happy do

  require Happy.Path

  @moduledoc """
  Happy path programming in elixir.
  """


  defmacro happy_path!([do: path = {:__block__, _, _}]) do
    Happy.Path.happy_path!(path)
  end
  defmacro happy_path!([do: x]), do: x

  defmacro happy_path!([do: path = {:__block__, _, _},
                         else: unhappy = [{:->, _, _} | _]]) do
    Happy.Path.happy_path!(path, unhappy)
  end
  defmacro happy_path!([do: x, else: [{:->, _, _} | _]]), do: x

  defmacro happy_path([do: path = {:__block__, _, _}]) do
    Happy.Path.happy_path(path)
  end
  defmacro happy_path([do: x]), do: x

  defmacro happy_path([do: path = {:__block__, _, _},
                        else: unhappy = [{:->, _, _} | _]]) do
    Happy.Path.happy_path(path, unhappy)
  end
  defmacro happy_path([do: x, else: [{:->, _, _} | _]]), do: x

end
