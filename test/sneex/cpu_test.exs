defmodule Sneex.CpuTest do
  use ExUnit.Case
  doctest Sneex.Cpu

  setup do
    cpu = <<0x00, 0x01, 0x02, 0x03, 0x04, 0x05>> |> Sneex.Memory.new() |> Sneex.Cpu.new()
    {:ok, cpu: cpu}
  end

  test "read_operand/2", %{cpu: cpu} do
    assert 0x01 == Sneex.Cpu.read_operand(cpu, 1)
    assert 0x0201 == Sneex.Cpu.read_operand(cpu, 2)
    assert 0x030201 == Sneex.Cpu.read_operand(cpu, 3)

    cpu = Sneex.Cpu.pc(cpu, 0x02)

    assert 0x03 == Sneex.Cpu.read_operand(cpu, 1)
    assert 0x0403 == Sneex.Cpu.read_operand(cpu, 2)
    assert 0x050403 == Sneex.Cpu.read_operand(cpu, 3)
  end

  describe "write_data/3" do
    test "16-bit", %{cpu: cpu} do
      cpu = Sneex.Cpu.acc_size(cpu, :bit16)

      data =
        cpu
        |> Sneex.Cpu.write_data(1, 0xDEAD)
        |> Sneex.Cpu.write_data(4, 0xBEEF)
        |> Sneex.Cpu.memory()
        |> Sneex.Memory.raw_data()

      assert <<0x00, 0xAD, 0xDE, 0x03, 0xEF, 0xBE>> == data
    end

    test "8-bit", %{cpu: cpu} do
      cpu = Sneex.Cpu.acc_size(cpu, :bit8)

      data =
        cpu
        |> Sneex.Cpu.write_data(0, 0xDE)
        |> Sneex.Cpu.write_data(1, 0xAD)
        |> Sneex.Cpu.write_data(2, 0xBE)
        |> Sneex.Cpu.write_data(3, 0xEF)
        |> Sneex.Cpu.write_data(4, 0xBEEF)
        |> Sneex.Cpu.memory()
        |> Sneex.Memory.raw_data()

      assert <<0xDE, 0xAD, 0xBE, 0xEF, 0xEF, 0x05>> == data
    end
  end
end
