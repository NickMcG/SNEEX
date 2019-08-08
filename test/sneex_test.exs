defmodule SneexTest do
  use ExUnit.Case
  doctest Sneex

  test "greets the world" do
    assert Sneex.hello() == :world
  end
end
