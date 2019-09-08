defmodule Sneex.Address.DirectPageTest do
  use ExUnit.Case
  alias Sneex.Address.{DirectPage, Mode}
  alias Sneex.{Cpu, Memory}
  use Bitwise

  setup do
    memory = <<0xFF, 0x00, 0x55, 0xAA, 0xFF>> |> Memory.new()
    cpu = memory |> Cpu.new() |> Cpu.emu_mode(:native)
    {:ok, cpu: cpu}
  end

  describe "8-bit" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.acc_size(:bit8)
      {:ok, cpu: cpu}
    end

    test "direct_page of 0x0000", %{cpu: cpu} do
      cpu = cpu |> Cpu.direct_page(0x0000)

      cpu |> Cpu.pc(0x0000) |> assert_behavior(0, 0, "$00")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(0, 0, "$55")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(0, 0, "$AA")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(0, 0, "$FF")
    end

    test "direct_page of 0x0001", %{cpu: cpu} do
      cpu = cpu |> Cpu.direct_page(0x0001)

      cpu |> Cpu.pc(0x0000) |> assert_behavior(0, 1, "$00")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(0, 1, "$55")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(0, 1, "$AA")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(0, 1, "$FF")
    end

    test "fetch/2 and store/3", %{cpu: cpu} do
      mode = cpu |> DirectPage.new()

      assert 0xFF == Mode.fetch(mode, cpu)
      <<0xAA, _rest::binary>> = mode |> Mode.store(cpu, 0xAA) |> Cpu.memory() |> Memory.raw_data()
    end
  end

  describe "16-bit" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.acc_size(:bit16)
      {:ok, cpu: cpu}
    end

    test "direct_page of 0x0000", %{cpu: cpu} do
      cpu = cpu |> Cpu.direct_page(0x0000)

      cpu |> Cpu.pc(0x0000) |> assert_behavior(1, 1, "$00")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(1, 1, "$55")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(1, 1, "$AA")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(1, 1, "$FF")
    end

    test "direct_page of 0x0001", %{cpu: cpu} do
      cpu = cpu |> Cpu.direct_page(0x0001)

      cpu |> Cpu.pc(0x0000) |> assert_behavior(1, 2, "$00")
      cpu |> Cpu.pc(0x0001) |> assert_behavior(1, 2, "$55")
      cpu |> Cpu.pc(0x0002) |> assert_behavior(1, 2, "$AA")
      cpu |> Cpu.pc(0x0003) |> assert_behavior(1, 2, "$FF")
    end

    test "fetch/2 and store/3", %{cpu: cpu} do
      mode = cpu |> DirectPage.new()

      assert 0x00FF == Mode.fetch(mode, cpu)

      <<0xAA, 0xBB, _rest::binary>> =
        mode |> Mode.store(cpu, 0xBBAA) |> Cpu.memory() |> Memory.raw_data()
    end
  end

  defp assert_behavior(cpu, fetch_cycles, store_cycles, disasm) do
    mode = cpu |> DirectPage.new()

    # assert fetch_cycles == Mode.fetch_cycles(mode)
    # assert store_cycles == Mode.store_cycles(mode)
    assert disasm == Mode.disasm(mode, cpu)
  end
end
