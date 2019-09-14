defmodule Sneex.Ops.MoveBitsTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, DirectPage, Indexed, Register}
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{MoveBits, Opcode}

  test "new/1 returns nil for unknown opcodes" do
    assert nil == MoveBits.new(0x42)
  end

  test "new/1 - shift left - accuulator address mode" do
    assert %MoveBits{address_mode: %Register{}, disasm: "ASL"} = MoveBits.new(0x0A)
  end

  test "new/1 - shift left - absolute address mode" do
    assert %MoveBits{address_mode: %Absolute{}, disasm: "ASL"} = MoveBits.new(0x0E)
  end

  test "new/1 - shift left - direct page address mode" do
    assert %MoveBits{address_mode: %DirectPage{}, disasm: "ASL"} = MoveBits.new(0x06)
  end

  test "new/1 - shift left - absolute, x-indexed address mode" do
    assert %MoveBits{address_mode: %Indexed{}, disasm: "ASL"} = MoveBits.new(0x1E)
  end

  test "new/1 - shift left - direct page, x-indexed address mode" do
    assert %MoveBits{address_mode: %Indexed{}, disasm: "ASL"} = MoveBits.new(0x16)
  end

  test "new/1 - shift right - accuulator address mode" do
    assert %MoveBits{address_mode: %Register{}, disasm: "LSR"} = MoveBits.new(0x4A)
  end

  test "new/1 - shift right - absolute address mode" do
    assert %MoveBits{address_mode: %Absolute{}, disasm: "LSR"} = MoveBits.new(0x4E)
  end

  test "new/1 - shift right - direct page address mode" do
    assert %MoveBits{address_mode: %DirectPage{}, disasm: "LSR"} = MoveBits.new(0x46)
  end

  test "new/1 - shift right - absolute, x-indexed address mode" do
    assert %MoveBits{address_mode: %Indexed{}, disasm: "LSR"} = MoveBits.new(0x5E)
  end

  test "new/1 - shift right - direct page, x-indexed address mode" do
    assert %MoveBits{address_mode: %Indexed{}, disasm: "LSR"} = MoveBits.new(0x56)
  end

  test "new/1 - rotate left - accuulator address mode" do
    assert %MoveBits{address_mode: %Register{}, disasm: "ROL"} = MoveBits.new(0x2A)
  end

  test "new/1 - rotate left - absolute address mode" do
    assert %MoveBits{address_mode: %Absolute{}, disasm: "ROL"} = MoveBits.new(0x2E)
  end

  test "new/1 - rotate left - direct page address mode" do
    assert %MoveBits{address_mode: %DirectPage{}, disasm: "ROL"} = MoveBits.new(0x26)
  end

  test "new/1 - rotate left - absolute, x-indexed address mode" do
    assert %MoveBits{address_mode: %Indexed{}, disasm: "ROL"} = MoveBits.new(0x3E)
  end

  test "new/1 - rotate left - direct page, x-indexed address mode" do
    assert %MoveBits{address_mode: %Indexed{}, disasm: "ROL"} = MoveBits.new(0x36)
  end

  test "new/1 - rotate right - accuulator address mode" do
    assert %MoveBits{address_mode: %Register{}, disasm: "ROR"} = MoveBits.new(0x6A)
  end

  test "new/1 - rotate right - absolute address mode" do
    assert %MoveBits{address_mode: %Absolute{}, disasm: "ROR"} = MoveBits.new(0x6E)
  end

  test "new/1 - rotate right - direct page address mode" do
    assert %MoveBits{address_mode: %DirectPage{}, disasm: "ROR"} = MoveBits.new(0x66)
  end

  test "new/1 - rotate right - absolute, x-indexed address mode" do
    assert %MoveBits{address_mode: %Indexed{}, disasm: "ROR"} = MoveBits.new(0x7E)
  end

  test "new/1 - rotate right - direct page, x-indexed address mode" do
    assert %MoveBits{address_mode: %Indexed{}, disasm: "ROR"} = MoveBits.new(0x76)
  end

  describe "behavior" do
    setup do
      cpu =
        <<>>
        |> Memory.new()
        |> Cpu.new()
        |> Cpu.emu_mode(:native)
        |> Cpu.acc_size(:bit8)
        |> Cpu.acc(0x88)

      {:ok, cpu: cpu}
    end

    test "shift left", %{cpu: cpu} do
      opcode = MoveBits.new(0x0A)
      assert "ASL A" == Opcode.disasm(opcode, cpu)
      assert 1 == Opcode.byte_size(opcode, cpu)
      assert 2 == Opcode.total_cycles(opcode, cpu)

      cpu
      |> assert_move(opcode, 0x10, true, false, false)
      |> assert_move(opcode, 0x20, false, false, false)
      |> assert_move(opcode, 0x40, false, false, false)
      |> assert_move(opcode, 0x80, false, false, true)
      |> assert_move(opcode, 0x00, true, true, false)
    end

    test "shift right", %{cpu: cpu} do
      opcode = MoveBits.new(0x4A)
      assert "LSR A" == Opcode.disasm(opcode, cpu)
      assert 1 == Opcode.byte_size(opcode, cpu)
      assert 2 == Opcode.total_cycles(opcode, cpu)

      cpu
      |> assert_move(opcode, 0x44, false, false, false)
      |> assert_move(opcode, 0x22, false, false, false)
      |> assert_move(opcode, 0x11, false, false, false)
      |> assert_move(opcode, 0x08, true, false, false)
      |> assert_move(opcode, 0x04, false, false, false)
      |> assert_move(opcode, 0x02, false, false, false)
      |> assert_move(opcode, 0x01, false, false, false)
      |> assert_move(opcode, 0x00, true, true, false)
    end

    test "rotate left", %{cpu: cpu} do
      opcode = MoveBits.new(0x2A)
      assert "ROL A" == Opcode.disasm(opcode, cpu)
      assert 1 == Opcode.byte_size(opcode, cpu)
      assert 2 == Opcode.total_cycles(opcode, cpu)

      cpu
      |> assert_move(opcode, 0x10, true, false, false)
      |> assert_move(opcode, 0x21, false, false, false)
      |> assert_move(opcode, 0x42, false, false, false)
      |> assert_move(opcode, 0x84, false, false, true)
      |> assert_move(opcode, 0x08, true, false, false)
    end

    test "rotate right", %{cpu: cpu} do
      opcode = MoveBits.new(0x6A)
      assert "ROR A" == Opcode.disasm(opcode, cpu)
      assert 1 == Opcode.byte_size(opcode, cpu)
      assert 2 == Opcode.total_cycles(opcode, cpu)

      cpu
      |> assert_move(opcode, 0x44, false, false, false)
      |> assert_move(opcode, 0x22, false, false, false)
      |> assert_move(opcode, 0x11, false, false, false)
      |> assert_move(opcode, 0x08, true, false, false)
      |> assert_move(opcode, 0x84, false, false, true)
      |> assert_move(opcode, 0x42, false, false, false)
      |> assert_move(opcode, 0x21, false, false, false)
      |> assert_move(opcode, 0x10, true, false, false)
      |> assert_move(opcode, 0x88, false, false, true)
    end
  end

  defp assert_move(cpu, opcode, expected_value, carry_flag, zero_flag, neg_flag) do
    cpu = opcode |> Opcode.execute(cpu)

    assert expected_value == Cpu.acc(cpu)
    assert carry_flag == Cpu.carry_flag(cpu)
    assert zero_flag == Cpu.zero_flag(cpu)
    assert neg_flag == Cpu.negative_flag(cpu)

    cpu
  end
end
