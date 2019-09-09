defmodule Sneex.Address.ImmediateTest do
  use ExUnit.Case
  alias Sneex.Address.{Immediate, Mode}
  alias Sneex.{Cpu, Memory}

  setup do
    memory = <<0xFF, 0x00, 0x00, 0x55, 0xAA, 0xFF>> |> Memory.new()
    cpu = memory |> Cpu.new() |> Cpu.emu_mode(:native)
    {:ok, cpu: cpu}
  end

  test "8-bit", %{cpu: cpu} do
    cpu = cpu |> Cpu.acc_size(:bit8)
    cpu |> Cpu.pc(0x0000) |> assert_behavior(1, 0x00, "#$00")
    cpu |> Cpu.pc(0x0001) |> assert_behavior(1, 0x00, "#$00")
    cpu |> Cpu.pc(0x0002) |> assert_behavior(1, 0x55, "#$55")
    cpu |> Cpu.pc(0x0003) |> assert_behavior(1, 0xAA, "#$AA")
    cpu |> Cpu.pc(0x0004) |> assert_behavior(1, 0xFF, "#$FF")
  end

  test "16-bit", %{cpu: cpu} do
    cpu = cpu |> Cpu.acc_size(:bit16)
    cpu |> Cpu.pc(0x0000) |> assert_behavior(2, 0x0000, "#$0000")
    cpu |> Cpu.pc(0x0001) |> assert_behavior(2, 0x5500, "#$5500")
    cpu |> Cpu.pc(0x0002) |> assert_behavior(2, 0xAA55, "#$AA55")
    cpu |> Cpu.pc(0x0003) |> assert_behavior(2, 0xFFAA, "#$FFAA")
  end

  defp assert_behavior(cpu, size, data, disasm) do
    mode = cpu |> Immediate.new()

    assert 0 == Mode.address(mode, cpu)
    assert size == Mode.byte_size(mode, cpu)
    assert data == Mode.fetch(mode, cpu)
    assert cpu == Mode.store(mode, cpu, 0xBEEF)
    assert disasm == Mode.disasm(mode, cpu)
  end
end
