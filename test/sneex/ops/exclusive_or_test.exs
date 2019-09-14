defmodule Sneex.Ops.ExclusiveOrTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, DirectPage, Immediate, Indexed, Indirect, Stack, Static}
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{ExclusiveOr, Opcode}

  test "new/1 returns nil for unknown opcodes" do
    assert nil == ExclusiveOr.new(0x42)
  end

  test "new/1 - immediate addressing mode" do
    assert %ExclusiveOr{address_mode: %Immediate{}} = ExclusiveOr.new(0x49)
  end

  test "new/1 - absolute addressing mode" do
    assert %ExclusiveOr{address_mode: %Absolute{}} = ExclusiveOr.new(0x4D)
  end

  test "new/1 - absolute long addressing mode" do
    assert %ExclusiveOr{address_mode: %Absolute{}} = ExclusiveOr.new(0x4F)
  end

  test "new/1 - direct page addressing mode" do
    assert %ExclusiveOr{address_mode: %DirectPage{}} = ExclusiveOr.new(0x45)
  end

  test "new/1 - direct page, indirect addressing mode" do
    assert %ExclusiveOr{address_mode: %Indirect{}} = ExclusiveOr.new(0x52)
  end

  test "new/1 - direct page, indirect long addressing mode" do
    assert %ExclusiveOr{address_mode: %Indirect{}} = ExclusiveOr.new(0x47)
  end

  test "new/1 - absolute, x-indexed addressing mode" do
    assert %ExclusiveOr{address_mode: %Indexed{}, preindex_mode: %Absolute{}, index_reg: :x} =
             ExclusiveOr.new(0x5D)
  end

  test "new/1 - absolute long, x-indexed addressing mode" do
    assert %ExclusiveOr{address_mode: %Indexed{}} = ExclusiveOr.new(0x5F)
  end

  test "new/1 - absolute, y-indexed addressing mode" do
    assert %ExclusiveOr{address_mode: %Indexed{}, preindex_mode: %Absolute{}, index_reg: :y} =
             ExclusiveOr.new(0x59)
  end

  test "new/1 - direct page, x-indexed addressing mode" do
    assert %ExclusiveOr{address_mode: %Indexed{}} = ExclusiveOr.new(0x55)
  end

  test "new/1 - direct page, x-indexed, indirect addressing mode" do
    assert %ExclusiveOr{address_mode: %Indirect{}} = ExclusiveOr.new(0x41)
  end

  test "new/1 - direct page indirect, y-indexed addressing mode" do
    assert %ExclusiveOr{address_mode: %Indexed{}} = ExclusiveOr.new(0x51)
  end

  test "new/1 - direct page indirect long, x-indexed addressing mode" do
    assert %ExclusiveOr{address_mode: %Indexed{}} = ExclusiveOr.new(0x57)
  end

  test "new/1 - stack relative addressing mode" do
    assert %ExclusiveOr{address_mode: %Stack{}} = ExclusiveOr.new(0x43)
  end

  test "new/1 - stack relative, indirect, y-indexed addressing mode" do
    assert %ExclusiveOr{address_mode: %Indexed{}} = ExclusiveOr.new(0x53)
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
      %ExclusiveOr{address_mode: static(0x00, 0)} |> assert_xor(cpu, 0xFF, false, true, 1)
    end

    test "0xFF and 0x88 -> 0x77", %{cpu: cpu} do
      %ExclusiveOr{address_mode: static(0x88, 4)} |> assert_xor(cpu, 0x77, false, false, 5)
    end

    test "0xFF and 0x77 -> 0x88", %{cpu: cpu} do
      %ExclusiveOr{address_mode: static(0x77, 3)} |> assert_xor(cpu, 0x88, false, true, 4)
    end

    test "0xFF and 0xFF -> 0x00", %{cpu: cpu} do
      %ExclusiveOr{address_mode: static(0xFF, 2)} |> assert_xor(cpu, 0x00, true, false, 3)
    end

    test "0xB2 and 0x77 -> 0xC5", %{cpu: cpu} do
      cpu = cpu |> Cpu.acc(0xB2)
      %ExclusiveOr{address_mode: static(0x77, 1)} |> assert_xor(cpu, 0xC5, false, true, 2)
    end
  end

  defp static(value, bytes), do: Static.new(0, bytes, value, "TEST")

  defp assert_xor(opcode, cpu, expected_value, zero_flag, neg_flag, bytes) do
    cpu = opcode |> Opcode.execute(cpu)

    assert expected_value == Cpu.acc(cpu)
    assert zero_flag == Cpu.zero_flag(cpu)
    assert neg_flag == Cpu.negative_flag(cpu)
    assert "EOR TEST" == Opcode.disasm(opcode, cpu)
    assert bytes == Opcode.byte_size(opcode, cpu)
  end
end
