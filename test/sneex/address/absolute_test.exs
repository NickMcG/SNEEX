defmodule Sneex.Address.AbsoluteTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, Mode}
  alias Sneex.{Cpu, Memory}
  use Bitwise

  setup do
    memory = <<0xFF, 0x00, 0x00, 0x55, 0xAA, 0xFF>> |> Memory.new()
    cpu = memory |> Cpu.new() |> Cpu.emu_mode(:native)
    {:ok, cpu: cpu}
  end

  describe "8-bit" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.acc_size(:bit8)
      {:ok, cpu: cpu}
    end

    test "for data", %{cpu: cpu} do
      cpu |> Cpu.pc(0x0000) |> assert_behavior(true, 0, "$0000")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(true, 0, "$5500")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(true, 0, "$AA55")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(true, 0, "$FFAA")
    end

    test "for program", %{cpu: cpu} do
      cpu |> Cpu.pc(0x0000) |> assert_behavior(false, 0, "$0000")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(false, 0, "$5500")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(false, 0, "$AA55")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(false, 0, "$FFAA")
    end

    test "fetch/2 and store/3", %{cpu: cpu} do
      mode = cpu |> Absolute.new(true)

      assert 0xFF == Mode.fetch(mode, cpu)
      <<0xAA, _rest::binary>> = mode |> Mode.store(cpu, 0xAA) |> Cpu.memory() |> Memory.raw_data()
    end
  end

  describe "16-bit" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.acc_size(:bit16)
      {:ok, cpu: cpu}
    end

    test "for data", %{cpu: cpu} do
      cpu |> Cpu.pc(0x0000) |> assert_behavior(true, 1, "$0000")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(true, 1, "$5500")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(true, 1, "$AA55")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(true, 1, "$FFAA")
    end

    test "for program", %{cpu: cpu} do
      cpu |> Cpu.pc(0x0000) |> assert_behavior(false, 1, "$0000")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(false, 1, "$5500")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(false, 1, "$AA55")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(false, 1, "$FFAA")
    end

    test "fetch/2 and store/3", %{cpu: cpu} do
      mode = cpu |> Absolute.new(true)

      assert 0x00FF == Mode.fetch(mode, cpu)

      <<0xAA, 0xBB, _rest::binary>> =
        mode |> Mode.store(cpu, 0xBBAA) |> Cpu.memory() |> Memory.raw_data()
    end
  end

  defp assert_behavior(cpu, is_data?, _extra_cycles, disasm) do
    mode = cpu |> Absolute.new(is_data?)

    # assert extra_cycles == Mode.fetch_cycles(mode)
    # assert extra_cycles == Mode.store_cycles(mode)
    assert disasm == Mode.disasm(mode, cpu)
  end
end
