defmodule Sneex.Address.IndirectTest do
  use ExUnit.Case
  alias Sneex.Address.{Indirect, Mode, Static}
  alias Sneex.{Cpu, Memory}
  use Bitwise

  setup do
    memory = <<0xFF, 0x04, 0x00, 0x00, 0xAA, 0xFF>> |> Memory.new()
    cpu = memory |> Cpu.new() |> Cpu.emu_mode(:native)
    static = Static.new(0x0001, 2, nil, "$0001")
    {:ok, cpu: cpu, static: static}
  end

  test "new_*/2", %{cpu: cpu, static: static} do
    cpu = cpu |> Cpu.program_bank(0x42) |> Cpu.data_bank(0x24)

    static |> Indirect.new_data(cpu) |> assert_behavior(cpu, 0x240004)
    static |> Indirect.new_program(cpu) |> assert_behavior(cpu, 0x420004)
    static |> Indirect.new_long(cpu) |> assert_behavior(cpu, 0x00004)
  end

  test "fetch/2 and store/3", %{cpu: cpu, static: static} do
    cpu = cpu |> Cpu.acc_size(:bit8)
    mode = static |> Indirect.new_long(cpu)

    assert 0xAA == Mode.fetch(mode, cpu)
    cpu = mode |> Mode.store(cpu, 0xDE)
    assert <<0xFF, 0x04, 0x00, 0x00, 0xDE, 0xFF>> = cpu |> Cpu.memory() |> Memory.raw_data()

    cpu = cpu |> Cpu.acc_size(:bit16)
    assert 0xFFDE == Mode.fetch(mode, cpu)
    cpu = mode |> Mode.store(cpu, 0xBEEF)
    assert <<0xFF, 0x04, 0x00, 0x00, 0xEF, 0xBE>> = cpu |> Cpu.memory() |> Memory.raw_data()
  end

  defp assert_behavior(mode, cpu, address) do
    assert address == Mode.address(mode)
    assert 2 == Mode.byte_size(mode)
    assert_disasm(mode, cpu)
  end

  defp assert_disasm(mode = %{is_long?: false}, cpu),
    do: assert("($0001)" == Mode.disasm(mode, cpu))

  defp assert_disasm(mode = %{is_long?: true}, cpu),
    do: assert("[$0001]" == Mode.disasm(mode, cpu))
end
