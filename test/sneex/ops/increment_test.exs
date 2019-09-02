defmodule Sneex.Ops.IncrementTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, DirectPage, Indexed, Register, Static}
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{Increment, Opcode}

  setup do
    cpu = <<0x00, 0x00, 0x00, 0x00>> |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    {:ok, cpu: cpu}
  end

  test "new/2 returns nil for unknown opcodes", %{cpu: cpu} do
    assert nil == Increment.new(0x42, cpu)
  end

  test "new/2 - accumulator addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0x1A, cpu)
    assert %Increment{address_mode: %Register{}} = opcode
    assert_basic_data(opcode, cpu, 1, 2, "INC A")
  end

  test "new/2 - absolute addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0xEE, cpu)
    assert %Increment{address_mode: %Absolute{}} = opcode
    assert_basic_data(opcode, cpu, 3, 6, "INC $0000")
  end

  test "new/2 - direct page addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0xE6, cpu)
    assert %Increment{address_mode: %DirectPage{}} = opcode
    assert_basic_data(opcode, cpu, 2, 5, "INC $00")
  end

  test "new/2 - absolute x-indexed addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0xFE, cpu)
    assert %Increment{address_mode: %Indexed{}} = opcode
    assert_basic_data(opcode, cpu, 3, 7, "INC $0000,X")
  end

  test "new/2 - direct page x-indexed addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0xF6, cpu)
    assert %Increment{address_mode: %Indexed{}} = opcode
    assert_basic_data(opcode, cpu, 2, 6, "INC $00,X")
  end

  test "new/2 - increment x", %{cpu: cpu} do
    opcode = Increment.new(0xE8, cpu)
    assert %Increment{address_mode: %Register{}} = opcode
    assert_basic_data(opcode, cpu, 1, 2, "INX")
  end

  test "new/2 - increment y", %{cpu: cpu} do
    opcode = Increment.new(0xC8, cpu)
    assert %Increment{address_mode: %Register{}} = opcode
    assert_basic_data(opcode, cpu, 1, 2, "INY")
  end

  describe "8-bit" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.acc_size(:bit8)
      {:ok, cpu: cpu}
    end

    test "increment - 0x00 -> 0x01", %{cpu: cpu} do
      {acc_opcode, index_opcode} = build_opcodes(cpu, 0x00)
      assert_increment(acc_opcode, cpu, 0x01, false, false)
      assert_increment(index_opcode, cpu, 0x01, false, false)
    end

    test "increment - 0x7F -> 0x80", %{cpu: cpu} do
      {acc_opcode, index_opcode} = build_opcodes(cpu, 0x7F)
      assert_increment(acc_opcode, cpu, 0x80, false, true)
      assert_increment(index_opcode, cpu, 0x80, false, true)
    end

    test "increment - 0xFF -> 0x00", %{cpu: cpu} do
      {acc_opcode, index_opcode} = build_opcodes(cpu, 0xFF)
      assert_increment(acc_opcode, cpu, 0x00, true, false)
      assert_increment(index_opcode, cpu, 0x00, true, false)
    end
  end

  describe "16-bit accumulator" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.acc_size(:bit16) |> Cpu.index_size(:bit16)
      {:ok, cpu: cpu}
    end

    test "increment - 0x0000 -> 0x0001", %{cpu: cpu} do
      {acc_opcode, index_opcode} = build_opcodes(cpu, 0x0000)
      assert_increment(acc_opcode, cpu, 0x0001, false, false)
      assert_increment(index_opcode, cpu, 0x0001, false, false)
    end

    test "increment - 0x7FFF -> 0x8000", %{cpu: cpu} do
      {acc_opcode, index_opcode} = build_opcodes(cpu, 0x7FFF)
      assert_increment(acc_opcode, cpu, 0x8000, false, true)
      assert_increment(index_opcode, cpu, 0x8000, false, true)
    end

    test "increment - 0xFFFF -> 0x0000", %{cpu: cpu} do
      {acc_opcode, index_opcode} = build_opcodes(cpu, 0xFFFF)
      assert_increment(acc_opcode, cpu, 0x0000, true, false)
      assert_increment(index_opcode, cpu, 0x0000, true, false)
    end
  end

  defp build_opcodes(cpu, base_value) do
    mode = Static.new(0, 2, 2, base_value, "test")

    acc_opcode = Increment.new(0x1A, cpu)
    acc_opcode = %Increment{acc_opcode | address_mode: mode}

    index_opcode = Increment.new(0xE8, cpu)
    index_opcode = %Increment{index_opcode | address_mode: mode}

    {acc_opcode, index_opcode}
  end

  defp execute_opcode(cpu, opcode) do
    opcode |> Opcode.execute(cpu)
  end

  defp assert_basic_data(opcode, cpu, size, cycles, disasm) do
    assert disasm == Opcode.disasm(opcode, cpu)
    assert size == Opcode.byte_size(opcode, cpu)
    assert cycles == Opcode.total_cycles(opcode, cpu)
  end

  defp assert_increment(opcode, cpu, value, zero_flag, negative_flag) do
    cpu = cpu |> execute_opcode(opcode)

    assert value == Cpu.acc(cpu)
    assert zero_flag == Cpu.zero_flag(cpu)
    assert negative_flag == Cpu.negative_flag(cpu)
  end
end
