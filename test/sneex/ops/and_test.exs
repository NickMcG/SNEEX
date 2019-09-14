defmodule Sneex.Ops.AndTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, DirectPage, Immediate, Indexed, Indirect, Stack, Static}
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{And, Opcode}

  test "new/1 returns nil for unknown opcodes" do
    assert nil == And.new(0x42)
  end

  test "new/1 - immediate addressing mode" do
    assert %And{address_mode: %Immediate{}} = And.new(0x29)
  end

  test "new/1 - absolute addressing mode" do
    assert %And{address_mode: %Absolute{}} = And.new(0x2D)
  end

  test "new/1 - absolute long addressing mode" do
    assert %And{address_mode: %Absolute{}} = And.new(0x2F)
  end

  test "new/1 - direct page addressing mode" do
    assert %And{address_mode: %DirectPage{}} = And.new(0x25)
  end

  test "new/1 - direct page, indirect addressing mode" do
    assert %And{address_mode: %Indirect{}} = And.new(0x32)
  end

  test "new/1 - direct page, indirect long addressing mode" do
    assert %And{address_mode: %Indirect{}} = And.new(0x27)
  end

  test "new/1 - absolute, x-indexed addressing mode" do
    assert %And{address_mode: %Indexed{}, preindex_mode: %Absolute{}, index_reg: :x} =
             And.new(0x3D)
  end

  test "new/1 - absolute long, x-indexed addressing mode" do
    assert %And{address_mode: %Indexed{}} = And.new(0x3F)
  end

  test "new/1 - absolute, y-indexed addressing mode" do
    assert %And{address_mode: %Indexed{}, preindex_mode: %Absolute{}, index_reg: :y} =
             And.new(0x39)
  end

  test "new/1 - direct page, x-indexed addressing mode" do
    assert %And{address_mode: %Indexed{}} = And.new(0x35)
  end

  test "new/1 - stack relative addressing mode" do
    assert %And{address_mode: %Stack{}} = And.new(0x23)
  end

  test "new/1 - stack relative, indirect, y-indexed addressing mode" do
    assert %And{address_mode: %Indexed{}} = And.new(0x33)
  end

  describe "execute/2" do
    setup do
      cpu =
        <<0x00, 0x88, 0x77, 0xFF>>
        |> Memory.new()
        |> Cpu.new()
        |> Cpu.emu_mode(:native)
        |> Cpu.acc_size(:bit8)
        |> Cpu.index_size(:bit16)
        |> Cpu.acc(0xFF)

      {:ok, cpu: cpu}
    end

    test "0xFF and 0x00 -> 0x00", %{cpu: cpu} do
      %And{address_mode: static(0x00, 0)} |> assert_and(cpu, 0x00, true, false, 1)
    end

    test "0xFF and 0x88 -> 0x88", %{cpu: cpu} do
      %And{address_mode: static(0x88, 4)} |> assert_and(cpu, 0x88, false, true, 5)
    end

    test "0xFF and 0x77 -> 0x77", %{cpu: cpu} do
      %And{address_mode: static(0x77, 3)} |> assert_and(cpu, 0x77, false, false, 4)
    end

    test "0xFF and 0xFF -> 0xFF", %{cpu: cpu} do
      %And{address_mode: static(0xFF, 2)} |> assert_and(cpu, 0xFF, false, true, 3)
    end

    test "0xB2 and 0x77 -> 0x32", %{cpu: cpu} do
      cpu = cpu |> Cpu.acc(0xB2)
      %And{address_mode: static(0x77, 1)} |> assert_and(cpu, 0x32, false, false, 2)
    end
  end

  defp static(value, bytes), do: Static.new(0, bytes, value, "TEST")

  defp assert_and(opcode, cpu, expected_value, zero_flag, neg_flag, bytes) do
    cpu = opcode |> Opcode.execute(cpu)

    assert expected_value == Cpu.acc(cpu)
    assert zero_flag == Cpu.zero_flag(cpu)
    assert neg_flag == Cpu.negative_flag(cpu)
    assert "AND TEST" == Opcode.disasm(opcode, cpu)
    assert bytes == Opcode.byte_size(opcode, cpu)
  end
end
