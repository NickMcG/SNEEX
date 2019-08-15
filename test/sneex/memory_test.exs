defmodule Sneex.MemoryTest do
  use ExUnit.Case

  test "new/1 and load_byte/2 will initialize the data and allow you to index it" do
    data = <<0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A>>
    memory = Sneex.Memory.new(data)

    assert 0x00 == Sneex.Memory.load_byte(memory, 0)
    assert 0x01 == Sneex.Memory.load_byte(memory, 1)
    assert 0x04 == Sneex.Memory.load_byte(memory, 4)
    assert 0x06 == Sneex.Memory.load_byte(memory, 6)
    assert 0x0A == Sneex.Memory.load_byte(memory, 10)
  end

  test "new/1 and load_word/2 will initialize the data and allow you to index it" do
    data = <<0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A>>
    memory = Sneex.Memory.new(data)

    assert 0x0100 == Sneex.Memory.load_word(memory, 0)
    assert 0x0201 == Sneex.Memory.load_word(memory, 1)
    assert 0x0504 == Sneex.Memory.load_word(memory, 4)
    assert 0x0706 == Sneex.Memory.load_word(memory, 6)
    assert 0x0A09 == Sneex.Memory.load_word(memory, 9)
  end

  test "new/1 and load_long/2 will initialize the data and allow you to index it" do
    data = <<0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A>>
    memory = Sneex.Memory.new(data)

    assert 0x020100 == Sneex.Memory.load_long(memory, 0)
    assert 0x030201 == Sneex.Memory.load_long(memory, 1)
    assert 0x060504 == Sneex.Memory.load_long(memory, 4)
    assert 0x080706 == Sneex.Memory.load_long(memory, 6)
    assert 0x0A0908 == Sneex.Memory.load_long(memory, 8)
  end
end
