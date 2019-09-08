defmodule Sneex.Ops.DecrementTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, CycleCalculator, DirectPage, Indexed, Register, Static}
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{Decrement, Opcode}

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
    assert nil == Decrement.new(cpu)
  end

  test "new/2 - accumulator addressing mode", %{cpu: cpu} do
    opcode = Decrement.new(0x3A, cpu)

    assert %Decrement{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %Register{}
           } = opcode
  end

  test "new/2 - absolute addressing mode", %{cpu: cpu} do
    opcode = Decrement.new(0xCE, cpu)

    assert %Decrement{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %Absolute{}
           } = opcode
  end

  test "new/2 - direct page addressing mode", %{cpu: cpu} do
    opcode = Decrement.new(0xC6, cpu)

    assert %Decrement{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %DirectPage{}
           } = opcode
  end

  test "new/2 - absolute x-indexed addressing mode", %{cpu: cpu} do
    opcode = Decrement.new(0xDE, cpu)

    assert %Decrement{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %Indexed{}
           } = opcode
  end

  test "new/2 - direct page x-indexed addressing mode", %{cpu: cpu} do
    opcode = Decrement.new(0xD6, cpu)

    assert %Decrement{
             disasm_override: nil,
             bit_size: :bit8,
             address_mode: %Indexed{}
           } = opcode
  end

  test "new/2 - increment x", %{cpu: cpu} do
    opcode = Decrement.new(0xCA, cpu)

    assert %Decrement{
             disasm_override: "DEX",
             bit_size: :bit16,
             address_mode: %Register{}
           } = opcode
  end

  test "decrement y", %{cpu: cpu} do
    opcode = Decrement.new(0x88, cpu)

    assert %Decrement{
             disasm_override: "DEY",
             bit_size: :bit16,
             address_mode: %Register{}
           } = opcode
  end

  test "byte_size/2", %{cpu: cpu} do
    op = %Decrement{address_mode: Static.new(0, 2, 9, "BAR")}
    assert 3 == Opcode.byte_size(op, cpu)
  end

  test "total_cycles/2", %{cpu: cpu} do
    ctor = &CycleCalculator.constant/1
    opcode = %Decrement{cycle_mods: [ctor.(1), ctor.(6)]}

    assert 7 == Opcode.total_cycles(opcode, cpu)
  end

  test "disasm/2", %{cpu: cpu} do
    with_override = %Decrement{disasm_override: "FOO"}
    assert "FOO" == Opcode.disasm(with_override, cpu)

    without_override = %Decrement{address_mode: Static.new(0, 0, 0, "BAR")}
    assert "DEC BAR" == Opcode.disasm(without_override, cpu)
  end

  describe "8-bit" do
    setup do
      {:ok, opcode: %Decrement{bit_size: :bit8}}
    end

    test "decrement - 0x01 -> 0x00", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x01)
      opcode = %Decrement{opcode | address_mode: mode}
      assert_decrement(opcode, cpu, 0x00, true, false)
    end

    test "decrement - 0x80 -> 0x7F", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x80)
      opcode = %Decrement{opcode | address_mode: mode}
      assert_decrement(opcode, cpu, 0x7F, false, false)
    end

    test "decrement - 0x00 -> 0xFF", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x00)
      opcode = %Decrement{opcode | address_mode: mode}
      assert_decrement(opcode, cpu, 0xFF, false, true)
    end
  end

  describe "16-bit" do
    setup %{cpu: cpu} do
      {:ok, cpu: Cpu.acc_size(cpu, :bit16), opcode: %Decrement{bit_size: :bit16}}
    end

    test "decrement - 0x0001 -> 0x0000", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x0001)
      opcode = %Decrement{opcode | address_mode: mode}
      assert_decrement(opcode, cpu, 0x0000, true, false)
    end

    test "decrement - 0x8000 -> 0x7FFF", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x8000)
      opcode = %Decrement{opcode | address_mode: mode}
      assert_decrement(opcode, cpu, 0x7FFF, false, false)
    end

    test "decrement - 0x0000 -> 0xFFFF", %{cpu: cpu, opcode: opcode} do
      mode = build_static_address_mode(0x0000)
      opcode = %Decrement{opcode | address_mode: mode}
      assert_decrement(opcode, cpu, 0xFFFF, false, true)
    end
  end

  defp build_static_address_mode(base_value), do: Static.new(0, 2, base_value, "test")

  defp assert_decrement(opcode, cpu, value, zero_flag, negative_flag) do
    cpu = opcode |> Opcode.execute(cpu)

    assert value == Cpu.acc(cpu)
    assert zero_flag == Cpu.zero_flag(cpu)
    assert negative_flag == Cpu.negative_flag(cpu)
  end
end
