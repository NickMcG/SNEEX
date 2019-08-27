defmodule Sneex.Ops.ProcessorStatusTest do
  use ExUnit.Case
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{Opcode, ProcessorStatus}

  test "new/1 returns nil for unknown opcodes" do
    assert nil == ProcessorStatus.new(0x42)
  end

  describe "clear carry bit (clc)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0x18)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "CLC" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.carry_flag(true)

      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.carry_flag(cpu)

      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.carry_flag(cpu)
    end
  end

  describe "set carry bit (sec)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0x38)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "SEC" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.carry_flag(false)

      cpu = cpu |> execute_opcode(opcode)
      assert true == Cpu.carry_flag(cpu)

      cpu = cpu |> execute_opcode(opcode)
      assert true == Cpu.carry_flag(cpu)
    end
  end

  describe "clear decimal mode (cld)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0xD8)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "CLD" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.decimal_mode(true)

      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.decimal_mode(cpu)

      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.decimal_mode(cpu)
    end
  end

  describe "set decimal mode (sed)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0xF8)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "SED" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.decimal_mode(false)

      cpu = cpu |> execute_opcode(opcode)
      assert true == Cpu.decimal_mode(cpu)

      cpu = cpu |> execute_opcode(opcode)
      assert true == Cpu.decimal_mode(cpu)
    end
  end

  describe "reset status bits (rep)" do
    setup do
      memory = <<0xC2, 0xFF, 0xC2, 0xAA, 0xC2, 0x00>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0xC2)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 3 == Opcode.total_cycles(opcode, cpu)
      assert "REP #$FF" == Opcode.disasm(opcode, memory, 0x0000)
    end

    test "execute/3, emulation mode", %{cpu: cpu, opcode: opcode} do
      # Should clear all except acc_size & index_size
      cpu =
        cpu
        |> Cpu.emu_mode(:emulation)
        |> set_all_flags()
        |> Cpu.pc(0x0000)
        |> execute_opcode(opcode)

      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.overflow_flag(cpu)
      assert :bit8 == Cpu.acc_size(cpu)
      assert :bit8 == Cpu.index_size(cpu)
      assert false == Cpu.decimal_mode(cpu)
      assert false == Cpu.irq_disable(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.carry_flag(cpu)

      # AA => 1010 1010 => Nxxx DxZx
      cpu = cpu |> set_all_flags() |> Cpu.pc(0x0002) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert true == Cpu.overflow_flag(cpu)
      assert :bit8 == Cpu.acc_size(cpu)
      assert :bit8 == Cpu.index_size(cpu)
      assert false == Cpu.decimal_mode(cpu)
      assert true == Cpu.irq_disable(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.carry_flag(cpu)

      # Shouldn't change anything
      cpu = cpu |> set_all_flags() |> Cpu.pc(0x0004) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert true == Cpu.overflow_flag(cpu)
      assert :bit8 == Cpu.acc_size(cpu)
      assert :bit8 == Cpu.index_size(cpu)
      assert true == Cpu.decimal_mode(cpu)
      assert true == Cpu.irq_disable(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert true == Cpu.carry_flag(cpu)
    end

    test "execute/3, native mode", %{cpu: cpu, opcode: opcode} do
      # Should clear all
      cpu =
        cpu
        |> Cpu.emu_mode(:native)
        |> set_all_flags()
        |> Cpu.pc(0x0000)
        |> execute_opcode(opcode)

      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.overflow_flag(cpu)
      assert :bit16 == Cpu.acc_size(cpu)
      assert :bit16 == Cpu.index_size(cpu)
      assert false == Cpu.decimal_mode(cpu)
      assert false == Cpu.irq_disable(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.carry_flag(cpu)

      # AA => 1010 1010 => NxMx DxZx
      cpu = cpu |> set_all_flags() |> Cpu.pc(0x0002) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert true == Cpu.overflow_flag(cpu)
      assert :bit16 == Cpu.acc_size(cpu)
      assert :bit8 == Cpu.index_size(cpu)
      assert false == Cpu.decimal_mode(cpu)
      assert true == Cpu.irq_disable(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.carry_flag(cpu)

      # Shouldn't change anything
      cpu = cpu |> set_all_flags() |> Cpu.pc(0x0004) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert true == Cpu.overflow_flag(cpu)
      assert :bit8 == Cpu.acc_size(cpu)
      assert :bit8 == Cpu.index_size(cpu)
      assert true == Cpu.decimal_mode(cpu)
      assert true == Cpu.irq_disable(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert true == Cpu.carry_flag(cpu)
    end
  end

  describe "set status bits (sep)" do
    setup do
      memory = <<0xE2, 0xFF, 0xE2, 0xAA, 0xE2, 0x00>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0xE2)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 3 == Opcode.total_cycles(opcode, cpu)
      assert "SEP #$FF" == Opcode.disasm(opcode, memory, 0x0000)
    end

    test "execute/3, emulation mode", %{cpu: cpu, opcode: opcode} do
      # Should clear all except acc_size & index_size
      cpu =
        cpu
        |> Cpu.emu_mode(:emulation)
        |> clear_all_flags()
        |> Cpu.pc(0x0000)
        |> execute_opcode(opcode)

      assert true == Cpu.negative_flag(cpu)
      assert true == Cpu.overflow_flag(cpu)
      assert :bit8 == Cpu.acc_size(cpu)
      assert :bit8 == Cpu.index_size(cpu)
      assert true == Cpu.decimal_mode(cpu)
      assert true == Cpu.irq_disable(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert true == Cpu.carry_flag(cpu)

      # AA => 1010 1010 => Nxxx DxZx
      cpu = cpu |> clear_all_flags() |> Cpu.pc(0x0002) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.overflow_flag(cpu)
      assert :bit8 == Cpu.acc_size(cpu)
      assert :bit8 == Cpu.index_size(cpu)
      assert true == Cpu.decimal_mode(cpu)
      assert false == Cpu.irq_disable(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.carry_flag(cpu)

      # Shouldn't change anything
      cpu = cpu |> clear_all_flags() |> Cpu.pc(0x0004) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.overflow_flag(cpu)
      assert :bit8 == Cpu.acc_size(cpu)
      assert :bit8 == Cpu.index_size(cpu)
      assert false == Cpu.decimal_mode(cpu)
      assert false == Cpu.irq_disable(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.carry_flag(cpu)
    end

    test "execute/3, native mode", %{cpu: cpu, opcode: opcode} do
      # Should set all
      cpu =
        cpu
        |> Cpu.emu_mode(:native)
        |> clear_all_flags()
        |> Cpu.pc(0x0000)
        |> execute_opcode(opcode)

      assert true == Cpu.negative_flag(cpu)
      assert true == Cpu.overflow_flag(cpu)
      assert :bit8 == Cpu.acc_size(cpu)
      assert :bit8 == Cpu.index_size(cpu)
      assert true == Cpu.decimal_mode(cpu)
      assert true == Cpu.irq_disable(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert true == Cpu.carry_flag(cpu)

      # AA => 1010 1010 => NxMx DxZx
      cpu = cpu |> clear_all_flags() |> Cpu.pc(0x0002) |> execute_opcode(opcode)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.overflow_flag(cpu)
      assert :bit8 == Cpu.acc_size(cpu)
      assert :bit16 == Cpu.index_size(cpu)
      assert true == Cpu.decimal_mode(cpu)
      assert false == Cpu.irq_disable(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.carry_flag(cpu)

      # Shouldn't change anything
      cpu = cpu |> clear_all_flags() |> Cpu.pc(0x0004) |> execute_opcode(opcode)
      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.overflow_flag(cpu)
      assert :bit16 == Cpu.acc_size(cpu)
      assert :bit16 == Cpu.index_size(cpu)
      assert false == Cpu.decimal_mode(cpu)
      assert false == Cpu.irq_disable(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.carry_flag(cpu)
    end
  end

  describe "clear interrupt disable flag (cli)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0x58)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "CLI" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.irq_disable(true)

      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.irq_disable(cpu)

      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.irq_disable(cpu)
    end
  end

  describe "set interrupt disable flag (sei)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0x78)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "SEI" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.irq_disable(false)

      cpu = cpu |> execute_opcode(opcode)
      assert true == Cpu.irq_disable(cpu)

      cpu = cpu |> execute_opcode(opcode)
      assert true == Cpu.irq_disable(cpu)
    end
  end

  describe "clear overflow flag (clv)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0xB8)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "CLV" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.overflow_flag(true)

      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.overflow_flag(cpu)

      cpu = cpu |> execute_opcode(opcode)
      assert false == Cpu.overflow_flag(cpu)
    end
  end

  describe "no operation (nop)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0xEA)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "NOP" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      assert cpu == execute_opcode(cpu, opcode)
    end
  end

  describe "exchange the B and A accumulators (xba)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0xEB)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 3 == Opcode.total_cycles(opcode, cpu)
      assert "XBA" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.emu_mode(:native) |> Cpu.acc_size(:bit16) |> Cpu.acc(0x0000)
      cpu = cpu |> Cpu.negative_flag(true) |> Cpu.zero_flag(false)

      cpu = execute_opcode(cpu, opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert true == Cpu.zero_flag(cpu)

      cpu = cpu |> Cpu.acc(0x8000) |> execute_opcode(opcode)
      assert 0x0080 == Cpu.acc(cpu)
      assert false == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)

      cpu = cpu |> execute_opcode(opcode)
      assert 0x8000 == Cpu.acc(cpu)
      assert true == Cpu.negative_flag(cpu)
      assert false == Cpu.zero_flag(cpu)
    end
  end

  describe "exchange carry and emulation bits (xce)" do
    setup do
      memory = <<>> |> Memory.new()
      cpu = Cpu.new(memory)

      {:ok, cpu: cpu, memory: memory, opcode: ProcessorStatus.new(0xFB)}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "XCE" == Opcode.disasm(opcode, cpu, memory)
    end

    test "execute/3", %{cpu: cpu, opcode: opcode} do
      cpu =
        cpu
        |> Cpu.emu_mode(:emulation)
        |> Cpu.carry_flag(false)
        |> Cpu.acc_size(:bit16)
        |> Cpu.index_size(:bit16)

      cpu = cpu |> execute_opcode(opcode)
      assert :native == Cpu.emu_mode(cpu)
      assert true == Cpu.carry_flag(cpu)
      assert :bit8 = Cpu.acc_size(cpu)
      assert :bit8 = Cpu.index_size(cpu)

      cpu = cpu |> execute_opcode(opcode)
      assert :emulation == Cpu.emu_mode(cpu)
      assert false == Cpu.carry_flag(cpu)
      assert :bit8 = Cpu.acc_size(cpu)
      assert :bit8 = Cpu.index_size(cpu)
      assert true == Cpu.break_flag(cpu)
    end
  end

  defp execute_opcode(cpu, opcode) do
    opcode |> Opcode.execute(cpu)
  end

  defp set_all_flags(cpu) do
    initialize_all_flags(cpu, :bit8, true)
  end

  defp clear_all_flags(cpu) do
    initialize_all_flags(cpu, :bit16, false)
  end

  defp initialize_all_flags(cpu, bit_size, value) do
    cpu
    |> Cpu.negative_flag(value)
    |> Cpu.overflow_flag(value)
    |> Cpu.acc_size(bit_size)
    |> Cpu.index_size(bit_size)
    |> Cpu.decimal_mode(value)
    |> Cpu.irq_disable(value)
    |> Cpu.zero_flag(value)
    |> Cpu.carry_flag(value)
  end
end
