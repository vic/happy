defmodule HappyTest do
  use ExUnit.Case
  import Happy

  def yeah({:ok, x}), do: "ok #{x}"
  def yeah(x), do: "yeah #{inspect(x)}"
  def nop(x), do: "nop #{inspect(x)}"

  test "passes match values down the pipe" do
    x =
    {:ok, "sure"}
    |> happy({:ok, _})
    |> yeah
    |> happy

    assert x == "ok sure"
  end

  test "doesnt pass non matching value to pipe" do
    x =
    {:error, "sure"}
    |> happy({:ok, _})
    |> yeah
    |> happy
    assert x == {:error, "sure"}
  end

  test "unhappy doesnt pass non matching value" do
    x =
    {:ok, "sure"}
    |> unhappy({:ok, _})
    |> yeah
    |> happy
    assert x == {:ok, "sure"}
  end


end
