defmodule Sneex.Address.IndexedTest do
  use ExUnit.Case
  alias Sneex.Address.{Indexed, Mode, Static}
  alias Sneex.{Cpu, Memory}
  use Bitwise

  setup do
    memory = <<0xFF, 0x00, 0x00, 0x55, 0xAA, 0xFF>> |> Memory.new()
    cpu = memory |> Cpu.new() |> Cpu.emu_mode(:native)
    static = Static.new(0x0000, 2, nil, "$F000")
    {:ok, cpu: cpu, static: static}
  end

  test "basic behavior", %{cpu: cpu, static: static} do
    cpu |> Cpu.x(0x00) |> Cpu.y(0x00) |> assert_behavior(static)
    cpu |> Cpu.x(0x01) |> Cpu.y(0x10) |> assert_behavior(static)
    cpu |> Cpu.x(0x02) |> Cpu.y(0x20) |> assert_behavior(static)
    cpu |> Cpu.x(0x03) |> Cpu.y(0x30) |> assert_behavior(static)
  end

  test "fetch/2 and store/3", %{cpu: cpu, static: static} do
    cpu = cpu |> Cpu.x(0x03) |> Cpu.y(0x04)
    x_mode = static |> Indexed.new(cpu, :x)
    y_mode = static |> Indexed.new(cpu, :y)

    assert 0x55 == Mode.fetch(x_mode, cpu)
    cpu = x_mode |> Mode.store(cpu, 0xDE)

    assert 0xAA == Mode.fetch(y_mode, cpu)
    cpu = y_mode |> Mode.store(cpu, 0xAD)

    <<0xFF, 0x00, 0x00, 0xDE, 0xAD, 0xFF>> = cpu |> Cpu.memory() |> Memory.raw_data()
  end

  defp assert_behavior(cpu, static = %{address: addr, disasm: disasm}) do
    x_mode = static |> Indexed.new(cpu, :x)
    y_mode = static |> Indexed.new(cpu, :y)

    assert addr + Cpu.x(cpu) == Mode.address(x_mode)
    assert "#{disasm},X" == Mode.disasm(x_mode, cpu)

    assert addr + Cpu.y(cpu) == Mode.address(y_mode)
    assert "#{disasm},Y" == Mode.disasm(y_mode, cpu)
  end
end
