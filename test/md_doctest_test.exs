defmodule MdDoctestTest do
  use ExUnit.Case
  doctest MdDoctest

  test "greets the world" do
    assert MdDoctest.hello() == :world
  end
end
