defmodule ClansTest do
  use ExUnit.Case
  doctest Clans

  test "greets the world" do
    assert Clans.hello() == :world
  end
end
