defmodule Happy.Macro do

  @moduledoc false

  # already piped code
  def piped(code = {:|>, _, _}), do: code

  # non calls
  def piped(code = {_, _, nil}), do: code

  # local functions
  def piped(code = {_, _, []}), do: code

  # tuple literals
  def piped(code = {:{}, _, _}), do: code

  # handle struct literals %Foo{}
  def piped(code = {:%, _, [_, {:%{}, _, _}]}) do
    code
  end

  def piped({call, ctx, [arg | args]}) do
    {:|>, [], [piped(arg), {call, ctx, args}]}
  end

  def piped(code), do: code

  def unpipe(piped_code) do
    piped_code |> Macro.unpipe |> Enum.map(fn {x,0} -> x end)
  end

  def rpipe(a, b) do
    Macro.pipe(b, a, 0)
  end


end
