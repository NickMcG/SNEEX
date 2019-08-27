defmodule Sneex.Ops.ProcessorStatus do
  @moduledoc """
  This represents the op codes for interacting with the processor status bits.
  This includes the following commands: CLC, SEC, CLD, SED, REP, SEP, SEI, CLI, and CLV
  """
  defstruct [:opcode]

  use Bitwise
  alias Sneex.{BasicTypes, Cpu, Memory}

  @opaque t :: %__MODULE__{
            opcode: 0x18 | 0x38 | 0xD8 | 0xF8 | 0xC2 | 0xE2 | 0x78 | 0x58 | 0xB8 | 0xEA
          }

  @spec new(byte()) :: nil | __MODULE__.t()

  def new(oc) when oc == 0x18 or oc == 0x38 or oc == 0xD8 or oc == 0xF8 or oc == 0xC2 do
    %__MODULE__{opcode: oc}
  end

  def new(oc) when oc == 0xE2 or oc == 0x78 or oc == 0x58 or oc == 0xB8 or oc == 0xEA do
    %__MODULE__{opcode: oc}
  end

  def new(_opcode), do: nil

  defimpl Sneex.Ops.Opcode do
    @clc 0x18
    @sec 0x38
    @cld 0xD8
    @sed 0xF8
    @rep 0xC2
    @sep 0xE2
    @sei 0x78
    @cli 0x58
    @clv 0xB8
    @nop 0xEA

    def byte_size(%{opcode: @clc}), do: 1
    def byte_size(%{opcode: @sec}), do: 1
    def byte_size(%{opcode: @cld}), do: 1
    def byte_size(%{opcode: @sed}), do: 1
    def byte_size(%{opcode: @rep}), do: 2
    def byte_size(%{opcode: @sep}), do: 2
    def byte_size(%{opcode: @sei}), do: 1
    def byte_size(%{opcode: @cli}), do: 1
    def byte_size(%{opcode: @clv}), do: 1
    def byte_size(%{opcode: @nop}), do: 1

    def total_cycles(%{opcode: @clc}, _cpu), do: 2
    def total_cycles(%{opcode: @sec}, _cpu), do: 2
    def total_cycles(%{opcode: @cld}, _cpu), do: 2
    def total_cycles(%{opcode: @sed}, _cpu), do: 2
    def total_cycles(%{opcode: @rep}, _cpu), do: 3
    def total_cycles(%{opcode: @sep}, _cpu), do: 3
    def total_cycles(%{opcode: @sei}, _cpu), do: 2
    def total_cycles(%{opcode: @cli}, _cpu), do: 2
    def total_cycles(%{opcode: @clv}, _cpu), do: 2
    def total_cycles(%{opcode: @nop}, _cpu), do: 2

    def execute(%{opcode: @clc}, cpu), do: cpu |> Cpu.carry_flag(false)
    def execute(%{opcode: @sec}, cpu), do: cpu |> Cpu.carry_flag(true)
    def execute(%{opcode: @cld}, cpu), do: cpu |> Cpu.decimal_mode(false)
    def execute(%{opcode: @sed}, cpu), do: cpu |> Cpu.decimal_mode(true)
    def execute(%{opcode: @sei}, cpu), do: cpu |> Cpu.irq_disable(true)
    def execute(%{opcode: @cli}, cpu), do: cpu |> Cpu.irq_disable(false)
    def execute(%{opcode: @clv}, cpu), do: cpu |> Cpu.overflow_flag(false)
    def execute(%{opcode: @nop}, cpu), do: cpu

    def execute(%{opcode: @rep}, cpu) do
      operand = Cpu.read_operand(cpu, 1)
      emu_mode = Cpu.emu_mode(cpu)

      {cpu, _} = {cpu, operand} |> modify_flags(emu_mode, false)
      cpu
    end

    def execute(%{opcode: @sep}, cpu) do
      operand = Cpu.read_operand(cpu, 1)
      emu_mode = Cpu.emu_mode(cpu)

      {cpu, _} = {cpu, operand} |> modify_flags(emu_mode, true)
      cpu
    end

    defp modify_flags(cpu_mask, _emulation_mode = :emulation, value) do
      cpu_mask
      |> modify_neg_flag(value)
      |> modify_overflow_flag(value)
      |> modify_decimal_mode(value)
      |> modify_irq_disable(value)
      |> modify_zero_flag(value)
      |> modify_carry_flag(value)
    end

    defp modify_flags(cpu_mask, _emulation_mode, false) do
      cpu_mask
      |> modify_neg_flag(false)
      |> modify_overflow_flag(false)
      |> modify_acc_size(:bit16)
      |> modify_index_size(:bit16)
      |> modify_decimal_mode(false)
      |> modify_irq_disable(false)
      |> modify_zero_flag(false)
      |> modify_carry_flag(false)
    end

    defp modify_flags(cpu_mask, _emulation_mode, _value) do
      cpu_mask
      |> modify_neg_flag(true)
      |> modify_overflow_flag(true)
      |> modify_acc_size(:bit8)
      |> modify_index_size(:bit8)
      |> modify_decimal_mode(true)
      |> modify_irq_disable(true)
      |> modify_zero_flag(true)
      |> modify_carry_flag(true)
    end

    defp modify_neg_flag({cpu, mask}, value) when (mask &&& 0x80) == 0x80 do
      {Cpu.negative_flag(cpu, value), mask}
    end

    defp modify_neg_flag(cpu_mask, _), do: cpu_mask

    defp modify_overflow_flag({cpu, mask}, value) when (mask &&& 0x40) == 0x40 do
      {Cpu.overflow_flag(cpu, value), mask}
    end

    defp modify_overflow_flag(cpu_mask, _), do: cpu_mask

    defp modify_acc_size({cpu, mask}, value) when (mask &&& 0x20) == 0x20 do
      {Cpu.acc_size(cpu, value), mask}
    end

    defp modify_acc_size(cpu_mask, _), do: cpu_mask

    defp modify_index_size({cpu, mask}, value) when (mask &&& 0x10) == 0x10 do
      {Cpu.index_size(cpu, value), mask}
    end

    defp modify_index_size(cpu_mask, _), do: cpu_mask

    defp modify_decimal_mode({cpu, mask}, value) when (mask &&& 0x08) == 0x08 do
      {Cpu.decimal_mode(cpu, value), mask}
    end

    defp modify_decimal_mode(cpu_mask, _), do: cpu_mask

    defp modify_irq_disable({cpu, mask}, value) when (mask &&& 0x04) == 0x04 do
      {Cpu.irq_disable(cpu, value), mask}
    end

    defp modify_irq_disable(cpu_mask, _), do: cpu_mask

    defp modify_zero_flag({cpu, mask}, value) when (mask &&& 0x02) == 0x02 do
      {Cpu.zero_flag(cpu, value), mask}
    end

    defp modify_zero_flag(cpu_mask, _), do: cpu_mask

    defp modify_carry_flag({cpu, mask}, value) when (mask &&& 0x01) == 0x01 do
      {Cpu.carry_flag(cpu, value), mask}
    end

    defp modify_carry_flag(cpu_mask, _), do: cpu_mask

    def disasm(%{opcode: @clc}, _memory, _address), do: "CLC"
    def disasm(%{opcode: @sec}, _memory, _address), do: "SEC"
    def disasm(%{opcode: @cld}, _memory, _address), do: "CLD"
    def disasm(%{opcode: @sed}, _memory, _address), do: "SED"
    def disasm(%{opcode: @sei}, _memory, _address), do: "SEI"
    def disasm(%{opcode: @cli}, _memory, _address), do: "CLI"
    def disasm(%{opcode: @clv}, _memory, _address), do: "CLV"
    def disasm(%{opcode: @nop}, _memory, _address), do: "NOP"

    def disasm(%{opcode: @rep}, memory, address) do
      status_bits = Memory.read_byte(memory, address + 1)
      "REP ##{BasicTypes.format_byte(status_bits)}"
    end

    def disasm(%{opcode: @sep}, memory, address) do
      status_bits = Memory.read_byte(memory, address + 1)
      "SEP ##{BasicTypes.format_byte(status_bits)}"
    end
  end
end
