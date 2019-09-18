defmodule Sneex.Ops.TestBitsTest do
  use ExUnit.Case
  alias Sneex.Address.{Absolute, DirectPage, Immediate, Indexed, Static}
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{Opcode, TestBits}

  test "new/1 returns nil for unknown opcodes" do
    assert nil == TestBits.new(0x42)
  end

  test "new/1 - BIT - accuulator address mode" do
    assert %TestBits{address_mode: %Immediate{}, disasm: "BIT"} = TestBits.new(0x89)
  end

  test "new/1 - BIT - absolute address mode" do
    assert %TestBits{address_mode: %Absolute{}, disasm: "BIT"} = TestBits.new(0x2C)
  end

  test "new/1 - BIT - direct page address mode" do
    assert %TestBits{address_mode: %DirectPage{}, disasm: "BIT"} = TestBits.new(0x24)
  end

  test "new/1 - BIT - absolute, x-indexed address mode" do
    assert %TestBits{address_mode: %Indexed{}, disasm: "BIT"} = TestBits.new(0x3C)
  end

  test "new/1 - BIT - direct page, x-indexed address mode" do
    assert %TestBits{address_mode: %Indexed{}, disasm: "BIT"} = TestBits.new(0x34)
  end

  test "new/1 - TRB - absolute address mode" do
    assert %TestBits{address_mode: %Absolute{}, disasm: "TRB"} = TestBits.new(0x1C)
  end

  test "new/1 - TRB - direct page address mode" do
    assert %TestBits{address_mode: %DirectPage{}, disasm: "TRB"} = TestBits.new(0x14)
  end

  test "new/1 - TSB - absolute address mode" do
    assert %TestBits{address_mode: %Absolute{}, disasm: "TSB"} = TestBits.new(0x0C)
  end

  test "new/1 - TSB - direct page address mode" do
    assert %TestBits{address_mode: %DirectPage{}, disasm: "TSB"} = TestBits.new(0x04)
  end

  describe "basic behavior" do
    setup do
      cpu = <<>> |> Memory.new() |> Cpu.new()
      mode = Static.new(0, 3, 0, "BAR")
      {:ok, cpu: cpu, opcode = %TestBit{address_mode: mode, disasm: "FOO"}}
    end

    test "byte_size/2", %{cpu: cpu, opcode: opcode} do
      assert 4 == Opcode.byte_size(opcode, cpu)
    end

    test "disasm/2", %{cpu: cpu, opcode: opcode} do
      assert "FOO BAR" == Opcode.disasm(opcode, cpu)
    end
  end
end
