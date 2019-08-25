defmodule Sneex.AddressModeTest do
  use ExUnit.Case
  alias Sneex.{AddressMode, Cpu, Memory}
  doctest Sneex.AddressMode

  setup do
    cpu = <<>> |> Memory.new() |> Cpu.new()
    {:ok, cpu: cpu}
  end

  test "absolute/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.data_bank(0x00)
    assert 0x000000 == AddressMode.absolute(cpu, 0x0000)
    assert 0x00DEAD == AddressMode.absolute(cpu, 0xDEAD)
    assert 0x00BEEF == AddressMode.absolute(cpu, 0xBEEF)
    assert 0x00FFFF == AddressMode.absolute(cpu, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0x01)
    assert 0x010000 == AddressMode.absolute(cpu, 0x0000)
    assert 0x01DEAD == AddressMode.absolute(cpu, 0xDEAD)
    assert 0x01BEEF == AddressMode.absolute(cpu, 0xBEEF)
    assert 0x01FFFF == AddressMode.absolute(cpu, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0xFF)
    assert 0xFF0000 == AddressMode.absolute(cpu, 0x0000)
    assert 0xFFDEAD == AddressMode.absolute(cpu, 0xDEAD)
    assert 0xFFBEEF == AddressMode.absolute(cpu, 0xBEEF)
    assert 0xFFFFFF == AddressMode.absolute(cpu, 0xFFFF)
  end

  test "direct_page/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.direct_page(0x0000)
    assert 0x000000 == AddressMode.direct_page(cpu, 0x0000)
    assert 0x00DEAD == AddressMode.direct_page(cpu, 0xDEAD)
    assert 0x00BEEF == AddressMode.direct_page(cpu, 0xBEEF)
    assert 0x00FFFF == AddressMode.direct_page(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x1111)
    assert 0x001111 == AddressMode.direct_page(cpu, 0x0000)
    assert 0x00EFBE == AddressMode.direct_page(cpu, 0xDEAD)
    assert 0x00D000 == AddressMode.direct_page(cpu, 0xBEEF)
    assert 0x001110 == AddressMode.direct_page(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x4242)
    assert 0x004242 == AddressMode.direct_page(cpu, 0x0000)
    assert 0x0020EF == AddressMode.direct_page(cpu, 0xDEAD)
    assert 0x000131 == AddressMode.direct_page(cpu, 0xBEEF)
    assert 0x004241 == AddressMode.direct_page(cpu, 0xFFFF)
  end

  test "absolute_indexed_x/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.data_bank(0x00) |> Cpu.x(0x0000) |> Cpu.index_size(:bit16)
    assert 0x000000 == AddressMode.absolute_indexed_x(cpu, 0x0000)
    assert 0x00DEAD == AddressMode.absolute_indexed_x(cpu, 0xDEAD)
    assert 0x00BEEF == AddressMode.absolute_indexed_x(cpu, 0xBEEF)
    assert 0x00FFFF == AddressMode.absolute_indexed_x(cpu, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0x01) |> Cpu.x(0x0142)
    assert 0x010142 == AddressMode.absolute_indexed_x(cpu, 0x0000)
    assert 0x01DFEF == AddressMode.absolute_indexed_x(cpu, 0xDEAD)
    assert 0x01C031 == AddressMode.absolute_indexed_x(cpu, 0xBEEF)
    assert 0x020141 == AddressMode.absolute_indexed_x(cpu, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0xFF) |> Cpu.index_size(:bit8)
    assert 0xFF0042 == AddressMode.absolute_indexed_x(cpu, 0x0000)
    assert 0xFFDEEF == AddressMode.absolute_indexed_x(cpu, 0xDEAD)
    assert 0xFFBF31 == AddressMode.absolute_indexed_x(cpu, 0xBEEF)
    assert 0x000041 == AddressMode.absolute_indexed_x(cpu, 0xFFFF)
  end

  test "direct_page_indexed_x/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.direct_page(0x0000) |> Cpu.x(0x0000) |> Cpu.index_size(:bit16)
    assert 0x000000 == AddressMode.direct_page_indexed_x(cpu, 0x0000)
    assert 0x00DEAD == AddressMode.direct_page_indexed_x(cpu, 0xDEAD)
    assert 0x00BEEF == AddressMode.direct_page_indexed_x(cpu, 0xBEEF)
    assert 0x00FFFF == AddressMode.direct_page_indexed_x(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x1111) |> Cpu.x(0x0142)
    assert 0x001253 == AddressMode.direct_page_indexed_x(cpu, 0x0000)
    assert 0x00F100 == AddressMode.direct_page_indexed_x(cpu, 0xDEAD)
    assert 0x00D142 == AddressMode.direct_page_indexed_x(cpu, 0xBEEF)
    assert 0x001252 == AddressMode.direct_page_indexed_x(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x4242) |> Cpu.index_size(:bit8)
    assert 0x004284 == AddressMode.direct_page_indexed_x(cpu, 0x0000)
    assert 0x002131 == AddressMode.direct_page_indexed_x(cpu, 0xDEAD)
    assert 0x000173 == AddressMode.direct_page_indexed_x(cpu, 0xBEEF)
    assert 0x004283 == AddressMode.direct_page_indexed_x(cpu, 0xFFFF)
  end
end
