defmodule Sneex.Address.AbsoluteTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, Mode}
  alias Sneex.{BasicTypes, Cpu, Memory}
  use Bitwise

  setup do
    memory = <<0xFF, 0x00, 0x00, 0x55, 0xAA, 0xFF>> |> Memory.new()

    cpu =
      memory
      |> Cpu.new()
      |> Cpu.emu_mode(:native)
      |> Cpu.program_bank(0x00)
      |> Cpu.data_bank(0x42)

    {:ok, cpu: cpu}
  end

  describe "8-bit" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.acc_size(:bit8)
      {:ok, cpu: cpu}
    end

    test "for data", %{cpu: cpu} do
      cpu |> Cpu.pc(0x0000) |> assert_behavior(true, 0x420000, "$0000")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(true, 0x425500, "$5500")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(true, 0x42AA55, "$AA55")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(true, 0x42FFAA, "$FFAA")
    end

    test "for program", %{cpu: cpu} do
      cpu |> Cpu.pc(0x0000) |> assert_behavior(false, 0x000000, "$0000")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(false, 0x005500, "$5500")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(false, 0x00AA55, "$AA55")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(false, 0x00FFAA, "$FFAA")
    end

    test "fetch/2 and store/3", %{cpu: cpu} do
      mode = cpu |> Absolute.new(false)

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
      cpu |> Cpu.pc(0x0000) |> assert_behavior(true, 0x420000, "$0000")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(true, 0x425500, "$5500")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(true, 0x42AA55, "$AA55")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(true, 0x42FFAA, "$FFAA")
    end

    test "for program", %{cpu: cpu} do
      cpu |> Cpu.pc(0x0000) |> assert_behavior(false, 0x000000, "$0000")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(false, 0x005500, "$5500")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(false, 0x00AA55, "$AA55")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(false, 0x00FFAA, "$FFAA")
    end

    test "fetch/2 and store/3", %{cpu: cpu} do
      mode = cpu |> Absolute.new(false)

      assert 0x00FF == Mode.fetch(mode, cpu)

      <<0xAA, 0xBB, _rest::binary>> =
        mode |> Mode.store(cpu, 0xBBAA) |> Cpu.memory() |> Memory.raw_data()
    end
  end

  test "long", %{cpu: cpu} do
    cpu = cpu |> Cpu.acc_size(:bit8)
    cpu |> Cpu.pc(0x0000) |> assert_long_behavior(0x550000)
    cpu |> Cpu.pc(0x0001) |> assert_long_behavior(0xAA5500)
    cpu |> Cpu.pc(0x0002) |> assert_long_behavior(0xFFAA55)
  end

  defp assert_behavior(cpu, is_data?, address, disasm) do
    mode = cpu |> Absolute.new(is_data?)
    assert %Absolute{address: ^address, is_long?: false} = mode
    assert disasm == Mode.disasm(mode, cpu)
  end

  defp assert_long_behavior(cpu, address) do
    mode = cpu |> Absolute.new_long()
    assert %Absolute{address: ^address, is_long?: true} = mode
    assert BasicTypes.format_long(address) == Mode.disasm(mode, cpu)
  end
end
