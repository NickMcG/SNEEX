defmodule Sneex.Ops.DecrementTest do
  use ExUnit.Case
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{Decrement, Opcode}
  alias Util.Test.DataBuilder

  test "new/1 returns nil for unknown opcodes" do
    assert nil == Decrement.new(0x42)
  end

  describe "accumulator addressing mode" do
    setup do
      data = <<0x00, 0x00, 0x00, 0x00>>
      memory = Memory.new(data)
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: Decrement.new(0x3A)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "DEC A" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      cpu = Cpu.acc_size(cpu, :bit16)

      # 0x0000 -> 0xFFFF
      cpu = Opcode.execute(opcode, cpu)

      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0xFFFF -> 0xFFFE
      cpu = Opcode.execute(opcode, cpu)

      assert 0xFFFE == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0x8000 -> 0x7FFF
      cpu = Cpu.acc(cpu, 0x8000)
      cpu = Opcode.execute(opcode, cpu)

      assert 0x7FFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # 0x0001 -> 0x0000
      cpu = Cpu.acc(cpu, 0x0001)
      cpu = Opcode.execute(opcode, cpu)

      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # 0x00 -> 0xFF
      cpu = cpu |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0xFF -> 0xFE
      cpu = cpu |> execute_opcode(opcode)
      assert 0xFE == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0x80 -> 0x7F
      cpu = cpu |> Cpu.acc(0x80) |> execute_opcode(opcode)
      assert 0x7F == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # 0x01 -> 0x00
      cpu = cpu |> Cpu.acc(0x01) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute addressing mode, 8-bit" do
    setup do
      data_to_dec = <<0x00, 0xFF, 0x80, 0x01>>
      commands = <<0xCE, 0x00, 0x00, 0xCE, 0x01, 0x00, 0xCE, 0x02, 0x00, 0xCE, 0x03, 0x00>>
      rest_of_page = DataBuilder.build_block_of_00s(Util.Bank.bank_size() - 16)
      page = data_to_dec <> commands <> rest_of_page
      data = page <> page

      memory = Memory.new(data)
      cpu = memory |> Cpu.new() |> Cpu.acc_size(:bit8)
      opcode = Decrement.new(0xCE)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      # direct page == 0
      assert 3 == Opcode.byte_size(opcode)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $0000" == Opcode.disasm(opcode, memory, 0x0004)

      # direct page != 0
      cpu = Cpu.data_bank(cpu, 0x01)
      assert 3 == Opcode.byte_size(opcode)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $0003" == Opcode.disasm(opcode, memory, 0x000D)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      # 0x00 -> 0xFF
      cpu = cpu |> Cpu.pc(0x0004) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0xFF -> 0xFE
      cpu = cpu |> Cpu.pc(0x0007) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0x80 -> 0x7F
      cpu = cpu |> Cpu.pc(0x000A) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # 0x01 -> 0x00
      cpu = cpu |> Cpu.pc(0x000D) |> execute_opcode(opcode)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      expected = <<0xFF, 0xFE, 0x7F, 0x00>>
      assert expected == get_memory_block(cpu, 0, 4)
    end
  end

  describe "absolute addressing mode, 16-bit" do
    setup do
      data_to_dec = <<0x00, 0x00, 0xFF, 0xFF, 0x00, 0x80, 0x01, 0x00>>
      commands = <<0xCE, 0x00, 0x00, 0xCE, 0x02, 0x00, 0xCE, 0x04, 0x00, 0xCE, 0x06, 0x00>>
      rest_of_page = DataBuilder.build_block_of_00s(Util.Bank.bank_size() - 20)
      page = data_to_dec <> commands <> rest_of_page
      data = page <> page

      memory = Memory.new(data)
      cpu = memory |> Cpu.new() |> Cpu.acc_size(:bit16)
      opcode = Decrement.new(0xCE)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      # direct page == 0
      assert 3 == Opcode.byte_size(opcode)
      assert 8 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $0002" == Opcode.disasm(opcode, memory, 0x000B)

      # direct page != 0
      cpu = Cpu.data_bank(cpu, 0x01)
      assert 3 == Opcode.byte_size(opcode)
      assert 8 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $0004" == Opcode.disasm(opcode, memory, 0x000E)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      # 0x0000 -> 0xFFFF
      cpu = cpu |> Cpu.pc(0x0008) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0xFFFF -> 0xFFFE
      cpu = cpu |> Cpu.pc(0x000B) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0x8000 -> 0x7FFF
      cpu = cpu |> Cpu.pc(0x000E) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # 0x0001 -> 0x0000
      cpu = cpu |> Cpu.pc(0x0011) |> execute_opcode(opcode)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      expected = <<0xFF, 0xFF, 0xFE, 0xFF, 0xFF, 0x7F, 0x00, 0x00>>
      assert expected == get_memory_block(cpu, 0, 8)
    end
  end

  describe "direct page addressing mode, 8-bit" do
    setup do
      data_to_inc = <<0x00, 0xFF, 0x80, 0x01>>
      commands = <<0xC6, 0x00, 0xC6, 0x01, 0xC6, 0x02, 0xC6, 0x03>>

      memory = Memory.new(data_to_inc <> commands)
      cpu = memory |> Cpu.new() |> Cpu.acc_size(:bit8)
      opcode = Decrement.new(0xC6)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 5 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $00" == Opcode.disasm(opcode, memory, 0x0004)

      cpu = Cpu.direct_page(cpu, 0x01)
      assert 2 == Opcode.byte_size(opcode)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $03" == Opcode.disasm(opcode, memory, 0x000A)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      # 0x00 -> 0xFF
      cpu = cpu |> Cpu.pc(0x0004) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0xFF -> 0xFE
      cpu = cpu |> Cpu.pc(0x0006) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x80 -> 0x7F
      cpu = cpu |> Cpu.pc(0x0008) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x01 -> 0x00
      cpu = cpu |> Cpu.pc(0x000A) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert true == Cpu.zero_flag(cpu)

      expected = <<0xFF, 0xFE, 0x7F, 0x00>>
      assert expected == get_memory_block(cpu, 0, 4)
    end
  end

  describe "direct page addressing mode, 16-bit" do
    setup do
      data_to_dec = <<0x00, 0x00, 0xFF, 0xFF, 0x00, 0x80, 0x01, 0x00>>
      commands = <<0xC6, 0x00, 0xC6, 0x02, 0xC6, 0x04, 0xC6, 0x06>>

      memory = Memory.new(data_to_dec <> commands)
      cpu = memory |> Cpu.new() |> Cpu.acc_size(:bit16)
      opcode = Decrement.new(0xC6)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $00" == Opcode.disasm(opcode, memory, 0x0008)

      assert 2 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $06" == Opcode.disasm(opcode, memory, 0x000E)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      # 0x0000 -> 0xFFFF
      cpu = cpu |> Cpu.pc(0x0008) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0xFFFF -> 0xFFFE
      cpu = cpu |> Cpu.pc(0x000A) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x8000 -> 0x7FFF
      cpu = cpu |> Cpu.pc(0x000C) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x0001 -> 0x0000
      cpu = cpu |> Cpu.pc(0x000E) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert true == Cpu.zero_flag(cpu)

      expected = <<0xFF, 0xFF, 0xFE, 0xFF, 0xFF, 0x7F, 0x00, 0x00>>
      assert expected == get_memory_block(cpu, 0, 8)
    end
  end

  describe "absolute x-indexed addressing mode, 8-bit" do
    setup do
      buffer = <<0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      data_to_dec = <<0x00, 0xFF, 0x80, 0x01>>
      commands = <<0xDE, 0x00, 0x00, 0xDE, 0x01, 0x00, 0xDE, 0x02, 0x00, 0xDE, 0x03, 0x00>>

      memory = Sneex.Memory.new(buffer <> buffer <> data_to_dec <> commands)
      cpu = memory |> Cpu.new() |> Cpu.acc_size(:bit8) |> Cpu.x(0x0010)
      opcode = Decrement.new(0xDE)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 3 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $0000,X" == Opcode.disasm(opcode, memory, 0x0014)

      assert 3 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $0002,X" == Opcode.disasm(opcode, memory, 0x001A)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      # 0x00 -> 0xFF
      cpu = cpu |> Cpu.pc(0x0014) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0xFF -> 0xFE
      cpu = cpu |> Cpu.pc(0x0017) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x80 -> 0x7F
      cpu = cpu |> Cpu.pc(0x001A) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x01 -> 0x00
      cpu = cpu |> Cpu.pc(0x001D) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert true == Cpu.zero_flag(cpu)

      expected = <<0xFF, 0xFE, 0x7F, 0x00>>
      assert expected == get_memory_block(cpu, 16, 4)
    end
  end

  describe "absolute x-indexed addressing mode, 16-bit" do
    setup do
      buffer = <<0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      data_to_dec = <<0x00, 0x00, 0xFF, 0xFF, 0x00, 0x80, 0x01, 0x00>>
      commands = <<0xDE, 0x00, 0x00, 0xDE, 0x02, 0x00, 0xDE, 0x04, 0x00, 0xDE, 0x06, 0x00>>

      memory = Sneex.Memory.new(buffer <> buffer <> data_to_dec <> commands)
      cpu = memory |> Cpu.new() |> Cpu.acc_size(:bit16) |> Cpu.index_size(:bit16) |> Cpu.x(0x0010)
      opcode = Decrement.new(0xDE)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 3 == Opcode.byte_size(opcode)
      assert 9 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $0000,X" == Opcode.disasm(opcode, memory, 0x0018)

      assert 3 == Opcode.byte_size(opcode)
      assert 9 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $0006,X" == Opcode.disasm(opcode, memory, 0x0021)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      # 0x0000 -> 0xFFFF
      cpu = cpu |> Cpu.pc(0x0018) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0xFFFF -> 0xFFFE
      cpu = cpu |> Cpu.pc(0x001B) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x8000 -> 0x7FFF
      cpu = cpu |> Cpu.pc(0x001E) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x0001 -> 0x0000
      cpu = cpu |> Cpu.pc(0x0021) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert true == Cpu.zero_flag(cpu)

      expected = <<0xFF, 0xFF, 0xFE, 0xFF, 0xFF, 0x7F, 0x00, 0x00>>
      assert expected == get_memory_block(cpu, 16, 8)
    end
  end

  describe "direct page x-indexed addressing mode, 8-bit" do
    setup do
      buffer = <<0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      data_to_dec = <<0x00, 0xFF, 0x80, 0x01>>
      commands = <<0xD6, 0x00, 0x00, 0xD6, 0x01, 0x00, 0xD6, 0x02, 0x00, 0xD6, 0x03, 0x00>>

      memory = Memory.new(buffer <> buffer <> data_to_dec <> commands)
      size = :bit8
      cpu = memory |> Cpu.new() |> Cpu.acc_size(size) |> Cpu.index_size(size) |> Cpu.x(0x0010)
      opcode = Decrement.new(0xD6)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $00,X" == Opcode.disasm(opcode, memory, 0x0014)

      cpu = Cpu.direct_page(cpu, 0x01)
      assert 2 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $02,X" == Opcode.disasm(opcode, memory, 0x001A)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      # 0x00 -> 0xFF
      cpu = cpu |> Cpu.pc(0x0014) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0xFF -> 0xFE
      cpu = cpu |> Cpu.pc(0x0017) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x80 -> 0x7F
      cpu = cpu |> Cpu.pc(0x001A) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      # 0x01 -> 0x00
      cpu = cpu |> Cpu.pc(0x001D) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert true == Cpu.zero_flag(cpu)

      expected = <<0xFF, 0xFE, 0x7F, 0x00>>
      assert expected == get_memory_block(cpu, 16, 4)
    end
  end

  describe "direct page x-indexed addressing mode, 16-bit" do
    setup do
      buffer = <<0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      data_to_dec = <<0x00, 0x00, 0xFF, 0xFF, 0x00, 0x80, 0x01, 0x00>>
      commands = <<0xD6, 0x00, 0xD6, 0x02, 0xD6, 0x04, 0xD6, 0x06>>

      memory = Memory.new(buffer <> buffer <> data_to_dec <> commands)
      cpu = memory |> Cpu.new() |> Cpu.index_size(:bit8) |> Cpu.acc_size(:bit16) |> Cpu.x(0x10)
      opcode = Decrement.new(0xD6)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 8 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $00,X" == Opcode.disasm(opcode, memory, 0x0018)

      cpu = Cpu.direct_page(cpu, 0x01)
      assert 2 == Opcode.byte_size(opcode)
      assert 9 == Opcode.total_cycles(opcode, cpu)
      assert "DEC $06,X" == Opcode.disasm(opcode, memory, 0x001E)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      # 0x0000 -> 0xFFFF
      cpu = cpu |> Cpu.pc(0x0018) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0xFFFF -> 0xFFFE
      cpu = cpu |> Cpu.pc(0x001A) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # 0x8000 -> 0x7FFF
      cpu = cpu |> Cpu.pc(0x001C) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # 0x0001 -> 0x0000
      cpu = cpu |> Cpu.pc(0x001E) |> execute_opcode(opcode)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      expected = <<0xFF, 0xFF, 0xFE, 0xFF, 0xFF, 0x7F, 0x00, 0x00>>
      assert expected == get_memory_block(cpu, 16, 8)
    end
  end

  describe "increment x" do
    setup do
      memory = Memory.new(<<>>)
      cpu = memory |> Cpu.new()
      opcode = Decrement.new(0xCA)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "DEX" == Opcode.disasm(opcode, memory, 0x0018)
    end

    test "execute/3, 8-bit", %{cpu: cpu, opcode: opcode} do
      # 0x00 -> 0xFF
      cpu = cpu |> Cpu.index_size(:bit8) |> Cpu.x(0x0000) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)
      assert 0x00FF == Cpu.x(cpu)

      # 0xFF -> 0xFE
      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)
      assert 0x00FE == Cpu.x(cpu)

      # 0x80 -> 0x7F
      cpu = cpu |> Cpu.x(0x0080) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert 0x007F == Cpu.x(cpu)

      # 0xFF -> 0x00
      cpu = cpu |> Cpu.x(0x0001) |> execute_opcode(opcode)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert 0x0000 == Cpu.x(cpu)
    end

    test "execute/3, 16-bit", %{cpu: cpu, opcode: opcode} do
      # 0x0000 -> 0xFFFF
      cpu = cpu |> Cpu.index_size(:bit16) |> Cpu.x(0x0000) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)
      assert 0xFFFF == Cpu.x(cpu)

      # 0xFFFF -> 0xFFFE
      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)
      assert 0xFFFE == Cpu.x(cpu)

      # 0x8000 -> 0x7FFF
      cpu = cpu |> Cpu.x(0x8000) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert 0x7FFF == Cpu.x(cpu)

      # 0x0001 -> 0x0000
      cpu = cpu |> Cpu.x(0x0001) |> execute_opcode(opcode)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert 0x0000 == Cpu.x(cpu)
    end
  end

  describe "decrement y" do
    setup do
      memory = Memory.new(<<>>)
      cpu = memory |> Cpu.new()
      opcode = Decrement.new(0x88)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "DEY" == Opcode.disasm(opcode, memory, 0x0018)
    end

    test "execute/3, 8-bit", %{cpu: cpu, opcode: opcode} do
      # 0x00 -> 0x01
      cpu = cpu |> Cpu.index_size(:bit8) |> Cpu.y(0x0000) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)
      assert 0x00FF == Cpu.y(cpu)

      # 0xFF -> 0xFE
      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)
      assert 0x00FE == Cpu.y(cpu)

      # 0x80 -> 0x7F
      cpu = cpu |> Cpu.y(0x0080) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert 0x007F == Cpu.y(cpu)

      # 0x01 -> 0x00
      cpu = cpu |> Cpu.y(0x0001) |> execute_opcode(opcode)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert 0x0000 == Cpu.y(cpu)
    end

    test "execute/3, 16-bit", %{cpu: cpu, opcode: opcode} do
      # 0x0000 -> 0xFFFF
      cpu = cpu |> Cpu.index_size(:bit16) |> Cpu.y(0x0000) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)
      assert 0xFFFF == Cpu.y(cpu)

      # 0xFFFF -> 0xFFFE
      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)
      assert 0xFFFE == Cpu.y(cpu)

      # 0x8000 -> 0x7FFF
      cpu = cpu |> Cpu.y(0x8000) |> execute_opcode(opcode)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert 0x7FFF == Cpu.y(cpu)

      # 0x0001 -> 0x0000
      cpu = cpu |> Cpu.y(0x0001) |> execute_opcode(opcode)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert 0x0000 == Cpu.y(cpu)
    end
  end

  defp execute_opcode(cpu, opcode) do
    opcode |> Opcode.execute(cpu)
  end

  defp get_memory_block(cpu, 0, block_size) do
    <<actual::binary-size(block_size), _rest::binary>> = cpu |> Cpu.memory() |> Memory.raw_data()

    actual
  end

  defp get_memory_block(cpu, skip, block_size) do
    <<_before::binary-size(skip), actual::binary-size(block_size), _rest::binary>> =
      cpu |> Cpu.memory() |> Memory.raw_data()

    actual
  end
end
