defmodule Sneex.MemoryTest do
  use ExUnit.Case

  setup do
    data = <<0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A>>
    {:ok, m: Sneex.Memory.new(data)}
  end

  test "new/1 and read_byte/2 will initialize the data and allow you to index it", %{m: m} do
    assert 0x00 == Sneex.Memory.read_byte(m, 0)
    assert 0x01 == Sneex.Memory.read_byte(m, 1)
    assert 0x04 == Sneex.Memory.read_byte(m, 4)
    assert 0x06 == Sneex.Memory.read_byte(m, 6)
    assert 0x0A == Sneex.Memory.read_byte(m, 10)
  end

  test "new/1 and read_word/2 will initialize the data and allow you to index it", %{m: m} do
    assert 0x0100 == Sneex.Memory.read_word(m, 0)
    assert 0x0201 == Sneex.Memory.read_word(m, 1)
    assert 0x0504 == Sneex.Memory.read_word(m, 4)
    assert 0x0706 == Sneex.Memory.read_word(m, 6)
    assert 0x0A09 == Sneex.Memory.read_word(m, 9)
  end

  test "new/1 and read_long/2 will initialize the data and allow you to index it", %{m: m} do
    assert 0x020100 == Sneex.Memory.read_long(m, 0)
    assert 0x030201 == Sneex.Memory.read_long(m, 1)
    assert 0x060504 == Sneex.Memory.read_long(m, 4)
    assert 0x080706 == Sneex.Memory.read_long(m, 6)
    assert 0x0A0908 == Sneex.Memory.read_long(m, 8)
  end

  test "write_*/3 will let you manipulate the data", %{m: m} do
    data =
      m
      |> Sneex.Memory.write_byte(0x000000, 0x12)
      |> Sneex.Memory.write_word(0x000001, 0xDEAD)
      |> Sneex.Memory.write_long(0x000003, 0xBE00EF)
      |> Sneex.Memory.write_word(0x000006, 0x0000)
      |> Sneex.Memory.write_long(0x000008, 0x000000)
      |> Sneex.Memory.raw_data()

    expected = <<0x12, 0xAD, 0xDE, 0xEF, 0x00, 0xBE, 0x00, 0x00, 0x00, 0x00, 0x00>>
    assert expected == data
  end
end
