defmodule Sneex.Ops.OrTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, DirectPage, Immediate, Indexed, Indirect, Stack, Static}
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{Opcode, Or}

  test "new/1 returns nil for unknown opcodes" do
    assert nil == Or.new(0x42)
  end

  test "new/1 - immediate addressing mode" do
    assert %Or{address_mode: %Immediate{}} = Or.new(0x09)
  end

  test "new/1 - absolute addressing mode" do
    assert %Or{address_mode: %Absolute{}} = Or.new(0x0D)
  end

  test "new/1 - absolute long addressing mode" do
    assert %Or{address_mode: %Absolute{}} = Or.new(0x0F)
  end

  test "new/1 - direct page addressing mode" do
    assert %Or{address_mode: %DirectPage{}} = Or.new(0x05)
  end

  test "new/1 - direct page, indirect addressing mode" do
    assert %Or{address_mode: %Indirect{}} = Or.new(0x12)
  end

  test "new/1 - direct page, indirect long addressing mode" do
    assert %Or{address_mode: %Indirect{}} = Or.new(0x07)
  end

  test "new/1 - absolute, x-indexed addressing mode" do
    assert %Or{address_mode: %Indexed{}, preindex_mode: %Absolute{}, index_reg: :x} = Or.new(0x1D)
  end

  test "new/1 - absolute long, x-indexed addressing mode" do
    assert %Or{address_mode: %Indexed{}} = Or.new(0x1F)
  end

  test "new/1 - absolute, y-indexed addressing mode" do
    assert %Or{address_mode: %Indexed{}, preindex_mode: %Absolute{}, index_reg: :y} = Or.new(0x19)
  end

  test "new/1 - direct page, x-indexed addressing mode" do
    assert %Or{address_mode: %Indexed{}} = Or.new(0x15)
  end

  test "new/1 - direct page, x-indexed, indirect addressing mode" do
    assert %Or{address_mode: %Indirect{}} = Or.new(0x01)
  end

  test "new/1 - direct page indirect, y-indexed addressing mode" do
    assert %Or{address_mode: %Indexed{}} = Or.new(0x11)
  end

  test "new/1 - direct page indirect long, x-indexed addressing mode" do
    assert %Or{address_mode: %Indexed{}} = Or.new(0x17)
  end

  test "new/1 - stack relative addressing mode" do
    assert %Or{address_mode: %Stack{}} = Or.new(0x03)
  end

  test "new/1 - stack relative, indirect, y-indexed addressing mode" do
    assert %Or{address_mode: %Indexed{}} = Or.new(0x13)
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

    test "0xFF and 0x00 -> 0xFF", %{cpu: cpu} do
      %Or{address_mode: static(0x00, 0)} |> assert_or(cpu, 0xFF, false, true, 1)
    end

    test "0xFF and 0x88 -> 0xFF", %{cpu: cpu} do
      %Or{address_mode: static(0x88, 4)} |> assert_or(cpu, 0xFF, false, true, 5)
    end

    test "0xFF and 0x77 -> 0xFF", %{cpu: cpu} do
      %Or{address_mode: static(0x77, 3)} |> assert_or(cpu, 0xFF, false, true, 4)
    end

    test "0xFF and 0xFF -> 0xFF", %{cpu: cpu} do
      %Or{address_mode: static(0xFF, 2)} |> assert_or(cpu, 0xFF, false, true, 3)
    end

    test "0xB2 and 0x77 -> 0xF7", %{cpu: cpu} do
      cpu = cpu |> Cpu.acc(0xB2)
      %Or{address_mode: static(0x77, 1)} |> assert_or(cpu, 0xF7, false, true, 2)
    end

    test "0x00 and 0x00 -> 0x00", %{cpu: cpu} do
      cpu = cpu |> Cpu.acc(0x00)
      %Or{address_mode: static(0x00, 1)} |> assert_or(cpu, 0x00, true, false, 2)
    end
  end

  defp static(value, bytes), do: Static.new(0, bytes, value, "TEST")

  defp assert_or(opcode, cpu, expected_value, zero_flag, neg_flag, bytes) do
    cpu = opcode |> Opcode.execute(cpu)

    assert expected_value == Cpu.acc(cpu)
    assert zero_flag == Cpu.zero_flag(cpu)
    assert neg_flag == Cpu.negative_flag(cpu)
    assert "ORA TEST" == Opcode.disasm(opcode, cpu)
    assert bytes == Opcode.byte_size(opcode, cpu)
  end
end
