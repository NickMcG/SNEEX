defmodule Sneex.Ops.IncrementTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, CycleCalculator, DirectPage, Indexed, Register, Static}
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{Increment, Opcode}

  setup do
    cpu =
      <<0x00, 0x00, 0x00, 0x00>>
      |> Memory.new()
      |> Cpu.new()
      |> Cpu.emu_mode(:native)
      |> Cpu.acc_size(:bit8)
      |> Cpu.index_size(:bit16)

    {:ok, cpu: cpu}
  end

  test "new/1 returns nil for unknown opcodes", %{cpu: cpu} do
    assert nil == Increment.new(cpu)
  end

  test "new/2 - accumulator addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0x1A, cpu)

    assert %Increment{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %Register{}
           } = opcode
  end

  test "new/2 - absolute addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0xEE, cpu)

    assert %Increment{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %Absolute{}
           } = opcode
  end

  test "new/2 - direct page addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0xE6, cpu)

    assert %Increment{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %DirectPage{}
           } = opcode
  end

  test "new/2 - absolute x-indexed addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0xFE, cpu)

    assert %Increment{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %Indexed{}
           } = opcode
  end

  test "new/2 - direct page x-indexed addressing mode", %{cpu: cpu} do
    opcode = Increment.new(0xF6, cpu)

    assert %Increment{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %Indexed{}
           } = opcode
  end

  test "new/2 - increment x", %{cpu: cpu} do
    opcode = Increment.new(0xE8, cpu)

    assert %Increment{
             disasm_override: "INX",
             bit_size: :bit16,
             address_mode: %Register{}
           } = opcode
  end

  test "new/2 - increment y", %{cpu: cpu} do
    opcode = Increment.new(0xC8, cpu)

    assert %Increment{
             disasm_override: "INY",
             bit_size: :bit16,
             address_mode: %Register{}
           } = opcode
  end

  test "byte_size/2", %{cpu: cpu} do
    op = %Increment{address_mode: Static.new(0, 2, 8, 0, "BAR")}
    assert 3 == Opcode.byte_size(op, cpu)
  end

  test "total_cycles/2", %{cpu: cpu} do
    ctor = &CycleCalculator.constant/1
    opcode = %Increment{cycle_mods: [ctor.(1), ctor.(6)]}

    assert 7 == Opcode.total_cycles(opcode, cpu)
  end

  test "disasm/2", %{cpu: cpu} do
    with_override = %Increment{disasm_override: "FOO"}
    assert "FOO" == Opcode.disasm(with_override, cpu)

    without_override = %Increment{address_mode: Static.new(0, 0, 0, 0, "BAR")}
    assert "INC BAR" == Opcode.disasm(without_override, cpu)
  end

  describe "8-bit" do
    setup do
      {:ok, opcode: %Increment{bit_size: :bit8}}
    end

    test "increment - 0x00 -> 0x01", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x00)
      opcode = %Increment{opcode | address_mode: mode}
      assert_increment(opcode, cpu, 0x01, false, false)
    end

    test "increment - 0x7F -> 0x80", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x7F)
      opcode = %Increment{opcode | address_mode: mode}
      assert_increment(opcode, cpu, 0x80, false, true)
    end

    test "increment - 0xFF -> 0x00", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0xFF)
      opcode = %Increment{opcode | address_mode: mode}
      assert_increment(opcode, cpu, 0x00, true, false)
    end
  end

  describe "16-bit" do
    setup %{cpu: cpu} do
      {:ok, cpu: Cpu.acc_size(cpu, :bit16), opcode: %Increment{bit_size: :bit16}}
    end

    test "increment - 0x0000 -> 0x0001", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x0000)
      opcode = %Increment{opcode | address_mode: mode}
      assert_increment(opcode, cpu, 0x0001, false, false)
    end

    test "increment - 0x7FFF -> 0x8000", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x7FFF)
      opcode = %Increment{opcode | address_mode: mode}
      assert_increment(opcode, cpu, 0x8000, false, true)
    end

    test "increment - 0xFFFF -> 0x0000", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0xFFFF)
      opcode = %Increment{opcode | address_mode: mode}
      assert_increment(opcode, cpu, 0x0000, true, false)
    end
  end

  defp build_static_address_mode(base_value), do: Static.new(0, 2, 2, base_value, "test")

  defp assert_increment(opcode, cpu, value, zero_flag, negative_flag) do
    cpu = opcode |> Opcode.execute(cpu)

    assert value == Cpu.acc(cpu)
    assert zero_flag == Cpu.zero_flag(cpu)
    assert negative_flag == Cpu.negative_flag(cpu)
  end
end
