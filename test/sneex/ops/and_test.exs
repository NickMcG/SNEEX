defmodule Sneex.Ops.AndTest do
  use ExUnit.Case
  alias Sneex.{Cpu, Memory}
  alias Sneex.Ops.{And, Opcode}
  alias Util.Test.DataBuilder

  test "new/1 returns nil for unknown opcodes" do
    assert nil == And.new(0x42)
  end

  describe "immediate addressing mode, 8-bit mode" do
    setup do
      memory = <<0x29, 0x00, 0x29, 0xAA, 0x29, 0xFF, 0x29, 0x55>> |> Memory.new()
      cpu = memory |> Cpu.new() |> Cpu.emu_mode(:emulation) |> Cpu.acc_size(:bit8)

      {:ok, cpu: cpu, opcode: And.new(0x29)}
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode, cpu)
      assert 2 == Opcode.total_cycles(opcode, cpu)
      assert "AND #$00" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> set_cpu(0x0002) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "immediate addressing mode, 16-bit mode" do
    setup do
      data = <<0x29, 0x00, 0x00, 0x29, 0xAA, 0xAA, 0x29, 0xFF, 0xFF, 0x29, 0x55, 0x55>>
      cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native) |> Cpu.acc_size(:bit16)

      {:ok, cpu: cpu, opcode: And.new(0x29)}
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      assert 3 == Opcode.byte_size(opcode, cpu)
      assert 3 == Opcode.total_cycles(opcode, cpu)
      assert "AND #$0000" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> set_cpu(0x0003) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x0009) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute addressing mode, 8-bit mode" do
    setup do
      data = <<0x2D, 0x00, 0x00, 0x2D, 0x20, 0x00, 0x2D, 0x40, 0x00, 0x2D, 0x60, 0x00>>

      setup(:bit8, data, 0x2D)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0006)
      assert 3 == Opcode.byte_size(opcode, cpu)
      assert 4 == Opcode.total_cycles(opcode, cpu)
      assert "AND $0040" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> set_cpu(0x0003) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x0009) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute addressing mode, 16-bit mode" do
    setup do
      data = <<0x2D, 0x00, 0x00, 0x2D, 0x20, 0x00, 0x2D, 0x40, 0x00, 0x2D, 0x60, 0x00>>

      setup(:bit16, data, 0x2D)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0006)
      assert 3 == Opcode.byte_size(opcode, cpu)
      assert 5 == Opcode.total_cycles(opcode, cpu)
      assert "AND $0040" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> set_cpu(0x0003) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x0009) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute long addressing mode, 8-bit mode" do
    setup do
      data =
        <<0x2F, 0x00, 0x00, 0x00, 0x2F, 0x20, 0x00, 0x00, 0x2F, 0x40, 0x00, 0x00, 0x2F, 0x60,
          0x00, 0x00>>

      setup(:bit8, data, 0x2F)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0008)
      assert 4 == Opcode.byte_size(opcode, cpu)
      assert 5 == Opcode.total_cycles(opcode, cpu)
      assert "AND $000040" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0008) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x000C) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute long addressing mode, 16-bit mode" do
    setup do
      data =
        <<0x2F, 0x00, 0x00, 0x00, 0x2F, 0x20, 0x00, 0x00, 0x2F, 0x40, 0x00, 0x00, 0x2F, 0x60,
          0x00, 0x00>>

      setup(:bit16, data, 0x2F)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0008)
      assert 4 == Opcode.byte_size(opcode, cpu)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "AND $000040" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0008) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x000C) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "direct page addressing mode, 8-bit mode" do
    setup do
      data = <<0x25, 0x00, 0x25, 0x20, 0x25, 0x40, 0x25, 0x60>>
      setup(:bit8, data, 0x25)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0004)
      assert 2 == Opcode.byte_size(opcode, cpu)
      assert 3 == Opcode.total_cycles(opcode, cpu)
      assert "AND $40" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> set_cpu(0x0002) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "direct page addressing mode, 16-bit mode" do
    setup do
      data = <<0x25, 0x00, 0x25, 0x20, 0x25, 0x40, 0x25, 0x60>>
      setup(:bit16, data, 0x25)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0004)
      assert 2 == Opcode.byte_size(opcode, cpu)
      assert 4 == Opcode.total_cycles(opcode, cpu)
      assert "AND $40" == Opcode.disasm(opcode, cpu)

      cpu = cpu |> Cpu.direct_page(0x0100)
      assert 5 == Opcode.total_cycles(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> set_cpu(0x0002) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "direct page, indirect addressing mode, 8-bit mode" do
    setup do
      data = <<0x32, 0xF4, 0x32, 0xF7, 0x32, 0xFA, 0x32, 0xFD>>
      setup(:bit8, data, 0x32)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0004)
      assert 2 == Opcode.byte_size(opcode, cpu)
      assert 5 == Opcode.total_cycles(opcode, cpu)
      assert "AND ($FA)" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> Cpu.direct_page(0xFF00) |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> set_cpu(0x0002) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "direct page, indirect addressing mode, 16-bit mode" do
    setup do
      data = <<0x32, 0xF4, 0x32, 0xF7, 0x32, 0xFA, 0x32, 0xFD>>
      setup(:bit16, data, 0x32)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0004)
      assert 2 == Opcode.byte_size(opcode, cpu)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "AND ($FA)" == Opcode.disasm(opcode, cpu)

      cpu = cpu |> Cpu.direct_page(0x0100)
      assert 7 == Opcode.total_cycles(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> Cpu.direct_page(0xFF00) |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> set_cpu(0x0002) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "direct page, indirect long addressing mode, 8-bit mode" do
    setup do
      data = <<0x27, 0xF4, 0x27, 0xF7, 0x27, 0xFA, 0x27, 0xFD>>
      setup(:bit8, data, 0x27)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0004)
      assert 2 == Opcode.byte_size(opcode, cpu)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "AND [$FA]" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> Cpu.direct_page(0xFF00) |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> set_cpu(0x0002) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "direct page, indirect long addressing mode, 16-bit mode" do
    setup do
      data = <<0x27, 0xF4, 0x27, 0xF7, 0x27, 0xFA, 0x27, 0xFD>>
      setup(:bit16, data, 0x27)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0004)
      assert 2 == Opcode.byte_size(opcode, cpu)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "AND [$FA]" == Opcode.disasm(opcode, cpu)

      cpu = cpu |> Cpu.direct_page(0x0100)
      assert 8 == Opcode.total_cycles(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> Cpu.direct_page(0xFF00) |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> set_cpu(0x0002) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute, x-indexed addressing mode, 8-bit mode" do
    setup do
      data = <<0x3D, 0x00, 0x00, 0x3D, 0x15, 0x00, 0x3D, 0x35, 0x00, 0x3D, 0x55, 0x00>>
      setup(:bit8, data, 0x3D)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0006)
      assert 3 == Opcode.byte_size(opcode, cpu)
      assert 4 == Opcode.total_cycles(opcode, cpu)
      assert "AND $0035, X" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> Cpu.x(0x000B) |> set_cpu(0x0003) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x0009) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute, x-indexed addressing mode, 16-bit mode" do
    setup do
      data = <<0x3D, 0x00, 0x00, 0x3D, 0x15, 0x00, 0x3D, 0x35, 0x00, 0x3D, 0x55, 0x00>>
      setup(:bit16, data, 0x3D)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0006)
      assert 3 == Opcode.byte_size(opcode, cpu)
      assert 5 == Opcode.total_cycles(opcode, cpu)
      assert "AND $0035, X" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> Cpu.x(0x000B) |> set_cpu(0x0003) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x0009) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute long, x-indexed addressing mode, 8-bit mode" do
    setup do
      data =
        <<0x3F, 0x00, 0x00, 0x00, 0x3F, 0x15, 0x00, 0x00, 0x3F, 0x35, 0x00, 0x00, 0x3F, 0x55,
          0x00, 0x00>>

      setup(:bit8, data, 0x3F)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0008)
      assert 4 == Opcode.byte_size(opcode, cpu)
      assert 5 == Opcode.total_cycles(opcode, cpu)
      assert "AND $000035, X" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> Cpu.x(0x000B) |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0008) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x000C) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute long, x-indexed addressing mode, 16-bit mode" do
    setup do
      data =
        <<0x3F, 0x00, 0x00, 0x00, 0x3F, 0x15, 0x00, 0x00, 0x3F, 0x35, 0x00, 0x00, 0x3F, 0x55,
          0x00, 0x00>>

      setup(:bit16, data, 0x3F)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0008)
      assert 4 == Opcode.byte_size(opcode, cpu)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "AND $000035, X" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> Cpu.x(0x000B) |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0008) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x000C) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute, y-indexed addressing mode, 8-bit mode" do
    setup do
      data = <<0x39, 0x00, 0x00, 0x39, 0x15, 0x00, 0x39, 0x35, 0x00, 0x39, 0x55, 0x00>>
      setup(:bit8, data, 0x39)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0006)
      assert 3 == Opcode.byte_size(opcode, cpu)
      assert 4 == Opcode.total_cycles(opcode, cpu)
      assert "AND $0035, Y" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> Cpu.y(0x000B) |> set_cpu(0x0003) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x0009) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "absolute, y-indexed addressing mode, 16-bit mode" do
    setup do
      data = <<0x39, 0x00, 0x00, 0x39, 0x15, 0x00, 0x39, 0x35, 0x00, 0x39, 0x55, 0x00>>
      setup(:bit16, data, 0x39)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0006)
      assert 3 == Opcode.byte_size(opcode, cpu)
      assert 5 == Opcode.total_cycles(opcode, cpu)
      assert "AND $0035, Y" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> Cpu.y(0x000B) |> set_cpu(0x0003) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x0009) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "direct page, x-indexed addressing mode, 8-bit mode" do
    setup do
      data = <<0x35, 0x00, 0x35, 0x15, 0x35, 0x35, 0x35, 0x55>>
      setup(:bit8, data, 0x35)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0004)
      assert 2 == Opcode.byte_size(opcode, cpu)
      assert 4 == Opcode.total_cycles(opcode, cpu)
      assert "AND $35, X" == Opcode.disasm(opcode, cpu)
    end

    test "execute/3 with 8-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x00
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x00 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAA
      cpu = cpu |> Cpu.x(0x000B) |> set_cpu(0x0002) |> execute_opcode(opcode)
      assert 0xAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFF
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x55
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0x55 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  describe "direct page, x-indexed addressing mode, 16-bit mode" do
    setup do
      data = <<0x35, 0x00, 0x35, 0x15, 0x35, 0x35, 0x35, 0x55>>
      setup(:bit16, data, 0x35)
    end

    test "basic data", %{cpu: cpu, opcode: opcode} do
      cpu = cpu |> Cpu.pc(0x0004)
      assert 2 == Opcode.byte_size(opcode, cpu)
      assert 5 == Opcode.total_cycles(opcode, cpu)
      assert "AND $35, X" == Opcode.disasm(opcode, cpu)

      cpu = cpu |> Cpu.direct_page(0x0100)
      assert 6 == Opcode.total_cycles(opcode, cpu)
    end

    test "execute/3 with 16-bit mode", %{cpu: cpu, opcode: opcode} do
      # operand: 0x0000
      cpu = cpu |> set_cpu(0x0000) |> execute_opcode(opcode)
      assert 0x0000 == Cpu.acc(cpu)
      assert true == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)

      # operand: 0xAAAA
      cpu = cpu |> Cpu.x(0x000B) |> set_cpu(0x0002) |> execute_opcode(opcode)
      assert 0xAAAA == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0xFFFF
      cpu = cpu |> set_cpu(0x0004) |> execute_opcode(opcode)
      assert 0xFFFF == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert true == Cpu.negative_flag(cpu)

      # operand: 0x5555
      cpu = cpu |> set_cpu(0x0006) |> execute_opcode(opcode)
      assert 0x5555 == Cpu.acc(cpu)
      assert false == Cpu.zero_flag(cpu)
      assert false == Cpu.negative_flag(cpu)
    end
  end

  defp execute_opcode(cpu, opcode), do: opcode |> Opcode.execute(cpu)

  defp set_cpu(cpu, pc), do: cpu |> Cpu.acc(0xFFFF) |> Cpu.pc(pc)

  defp setup(bit_size, custom_data, opcode) do
    data = build_bank0() <> custom_data

    cpu =
      data
      |> Memory.new()
      |> Cpu.new()
      |> Cpu.emu_mode(:native)
      |> Cpu.acc_size(bit_size)
      |> Cpu.program_bank(0x01)

    {:ok, cpu: cpu, opcode: And.new(opcode)}
  end

  # Bank 0 is going to have all 0's, except for the following spots:
  # 0x0020 & 0x0021 will have 0xAA
  # 0x0040 & 0x0041 will have 0xFF
  # 0x0060 & 0x0061 will have 0x55
  # indirect block starting at end of page
  #      (FFF4 => 0000, FFF7 => 0020, FFFA => 0040, FFFD => 0060)
  defp build_bank0 do
    a = <<0xAA, 0xAA>>
    f = <<0xFF, 0xFF>>
    fives = <<0x55, 0x55>>
    id = &<<&1, 0x00, 0x00>>
    indirect = id.(0x00) <> id.(0x20) <> id.(0x40) <> id.(0x60)

    before = DataBuilder.build_block_of_00s(0x20)
    between = DataBuilder.build_block_of_00s(0x1E)
    rest = DataBuilder.build_block_of_00s(0xFF92)

    before <> a <> between <> f <> between <> fives <> rest <> indirect
  end
end
