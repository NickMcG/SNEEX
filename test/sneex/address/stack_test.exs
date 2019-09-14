defmodule Sneex.Address.StackTest do
  use ExUnit.Case
  alias Sneex.Address.{Mode, Stack}
  alias Sneex.{Cpu, Memory}
  # use Bitwise

  setup do
    cpu =
      <<0x00, 0x01, 0x42, 0xFF>>
      |> Memory.new()
      |> Cpu.new()
      |> Cpu.emu_mode(:native)
      |> Cpu.acc_size(:bit8)

    mode = Stack.new()
    {:ok, cpu: cpu, mode: mode}
  end

  test "basic behavior", %{cpu: cpu, mode: mode} do
    cpu = cpu |> Cpu.pc(0x0000) |> Cpu.stack_ptr(0xFF24)
    assert 0xFF25 == Mode.address(mode, cpu)
    assert "$01,S" == Mode.disasm(mode, cpu)
    assert 1 == Mode.byte_size(mode, cpu)

    cpu = cpu |> Cpu.pc(0x0001)
    assert 0xFF66 == Mode.address(mode, cpu)
    assert "$42,S" == Mode.disasm(mode, cpu)
    assert 1 == Mode.byte_size(mode, cpu)

    cpu = cpu |> Cpu.pc(0x0002)
    assert 0x0023 == Mode.address(mode, cpu)
    assert "$FF,S" == Mode.disasm(mode, cpu)
    assert 1 == Mode.byte_size(mode, cpu)
  end

  test "fetch/2 & store/3", %{cpu: cpu, mode: mode} do
    cpu = cpu |> Cpu.pc(0x0000) |> Cpu.stack_ptr(0x0001)
    assert 0x42 == Mode.fetch(mode, cpu)

    cpu = Mode.store(mode, cpu, 0xBE)
    assert 0xBE == Mode.fetch(mode, cpu)
  end
end
