defmodule Sneex.Address.RegisterTest do
  use ExUnit.Case
  alias Sneex.Address.{Mode, Register}
  alias Sneex.{Cpu, Memory}
  use Bitwise

  setup do
    cpu =
      <<>>
      |> Memory.new()
      |> Cpu.new()
      |> Cpu.emu_mode(:native)
      |> Cpu.x(0xDEAD)
      |> Cpu.y(0xBEEF)
      |> Cpu.acc(0xABBA)

    x_mode = Register.new(:x)
    y_mode = Register.new(:y)
    acc_mode = Register.new(:acc)
    {:ok, cpu: cpu, x_mode: x_mode, y_mode: y_mode, acc_mode: acc_mode}
  end

  describe "8-bit" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.acc_size(:bit8) |> Cpu.index_size(:bit8)
      {:ok, cpu: cpu}
    end

    test "behavior", %{cpu: cpu, x_mode: x, y_mode: y, acc_mode: acc} do
      assert 0x0000 == Mode.address(x)
      # assert 0 == Mode.fetch_cycles(x)
      # assert 0 == Mode.store_cycles(x)
      assert "X" == Mode.disasm(x, cpu)
      assert 0xAD == Mode.fetch(x, cpu)

      cpu = Mode.store(x, cpu, 0xBEEB)
      assert 0xEB == Cpu.x(cpu)

      assert 0x0000 == Mode.address(y)
      # assert 0 == Mode.fetch_cycles(y)
      # assert 0 == Mode.store_cycles(y)
      assert "Y" == Mode.disasm(y, cpu)
      assert 0xEF == Mode.fetch(y, cpu)

      cpu = Mode.store(y, cpu, 0xBEEB)
      assert 0xEB == Cpu.y(cpu)

      assert 0x0000 == Mode.address(acc)
      # assert 0 == Mode.fetch_cycles(acc)
      # assert 0 == Mode.store_cycles(acc)
      assert "A" == Mode.disasm(acc, cpu)
      assert 0xBA == Mode.fetch(acc, cpu)

      cpu = Mode.store(acc, cpu, 0xBEEB)
      assert 0xEB == Cpu.acc(cpu)
    end
  end

  describe "16-bit" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.acc_size(:bit16) |> Cpu.index_size(:bit16)
      {:ok, cpu: cpu}
    end

    test "behavior", %{cpu: cpu, x_mode: x, y_mode: y, acc_mode: acc} do
      assert 0x0000 == Mode.address(x)
      # assert 0 == Mode.fetch_cycles(x)
      # assert 0 == Mode.store_cycles(x)
      assert "X" == Mode.disasm(x, cpu)
      assert 0xDEAD == Mode.fetch(x, cpu)

      cpu = Mode.store(x, cpu, 0xBEEB)
      assert 0xBEEB == Cpu.x(cpu)

      assert 0x0000 == Mode.address(y)
      # assert 0 == Mode.fetch_cycles(y)
      # assert 0 == Mode.store_cycles(y)
      assert "Y" == Mode.disasm(y, cpu)
      assert 0xBEEF == Mode.fetch(y, cpu)

      cpu = Mode.store(y, cpu, 0xBEEB)
      assert 0xBEEB == Cpu.y(cpu)

      assert 0x0000 == Mode.address(acc)
      # assert 0 == Mode.fetch_cycles(acc)
      # assert 0 == Mode.store_cycles(acc)
      assert "A" == Mode.disasm(acc, cpu)
      assert 0xABBA == Mode.fetch(acc, cpu)

      cpu = Mode.store(acc, cpu, 0xBEEB)
      assert 0xBEEB == Cpu.acc(cpu)
    end
  end
end
