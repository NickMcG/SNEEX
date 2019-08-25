defmodule Sneex.Ops.Increment do
  @moduledoc """
  This represents the op codes for incrementing a value (INC, INX, and INY).
  """
  defstruct [:opcode]

  use Bitwise
  alias Sneex.{BasicTypes, Cpu, Memory}

  @opaque t :: %__MODULE__{opcode: 0x1A | 0xEE | 0xE6 | 0xFE | 0xF6}

  @spec new(byte()) :: nil | __MODULE__.t()

  def new(0x1A), do: %__MODULE__{opcode: 0x1A}
  def new(0xEE), do: %__MODULE__{opcode: 0xEE}
  def new(0xE6), do: %__MODULE__{opcode: 0xE6}
  def new(0xFE), do: %__MODULE__{opcode: 0xFE}
  def new(0xF6), do: %__MODULE__{opcode: 0xF6}

  def new(_opcode), do: nil

  defimpl Sneex.Ops.Opcode do
    def byte_size(%{opcode: 0x1A}), do: 1
    def byte_size(%{opcode: 0xEE}), do: 3
    def byte_size(%{opcode: 0xE6}), do: 2
    def byte_size(%{opcode: 0xFE}), do: 3
    def byte_size(%{opcode: 0xF6}), do: 2

    def total_cycles(%{opcode: 0x1A}, _cpu), do: 2

    def total_cycles(%{opcode: 0xEE}, cpu) do
      status_cycles = cpu |> Cpu.acc_size() |> add_16_bit_cycles()
      6 + status_cycles
    end

    def total_cycles(%{opcode: 0xE6}, cpu) do
      status_cycles = cpu |> Cpu.acc_size() |> add_16_bit_cycles()
      page_cycles = cpu |> Cpu.direct_page() |> add_direct_page_cycles()
      5 + status_cycles + page_cycles
    end

    def total_cycles(%{opcode: 0xFE}, cpu) do
      status_cycles = cpu |> Cpu.acc_size() |> add_16_bit_cycles()
      7 + status_cycles
    end

    def total_cycles(%{opcode: 0xF6}, cpu) do
      status_cycles = cpu |> Cpu.acc_size() |> add_16_bit_cycles()
      page_cycles = cpu |> Cpu.direct_page() |> add_direct_page_cycles()
      6 + status_cycles + page_cycles
    end

    defp add_16_bit_cycles(:bit8), do: 0
    defp add_16_bit_cycles(_status), do: 2

    defp add_direct_page_cycles(0x00), do: 0
    defp add_direct_page_cycles(_), do: 1

    def execute(%{opcode: 0x1A}, cpu) do
      {new_a, cpu} = cpu |> Cpu.acc() |> increment(cpu)
      cpu |> Cpu.acc(new_a)
    end

    def execute(%{opcode: 0xEE}, cpu) do
      read_fn = &Cpu.read_absolute_address/2
      write_fn = &Cpu.write_absolute_address/3
      increment(2, read_fn, write_fn, cpu)
    end

    def execute(%{opcode: 0xE6}, cpu) do
      read_fn = &Cpu.read_direct_page/2
      write_fn = &Cpu.write_direct_page/3
      increment(1, read_fn, write_fn, cpu)
    end

    def execute(%{opcode: 0xFE}, cpu) do
      read_fn = &Cpu.read_absolute_indexed_x/2
      write_fn = &Cpu.write_absolute_indexed_x/3
      increment(2, read_fn, write_fn, cpu)
    end

    def execute(%{opcode: 0xF6}, cpu) do
      read_fn = &Cpu.read_direct_page_indexed_x/2
      write_fn = &Cpu.write_direct_page_indexed_x/3
      increment(1, read_fn, write_fn, cpu)
    end

    defp increment(operand_bytes, read_fn, write_fn, cpu = %Cpu{}) do
      operand = Cpu.read_operand(cpu, operand_bytes)
      data = read_fn.(cpu, operand)
      {new_value, cpu} = increment(data, cpu)
      write_fn.(cpu, operand, new_value)
    end

    defp increment(value, cpu = %Cpu{}) do
      bitness = cpu |> Cpu.acc_size()
      {new_value, zf, nf} = increment(value, bitness)

      new_cpu = cpu |> Cpu.zero_flag(zf) |> Cpu.negative_flag(nf)
      {new_value, new_cpu}
    end

    defp increment(0xFF, :bit8), do: {0, true, false}
    defp increment(value, :bit8) when value >= 0x7F, do: {value + 1, false, true}
    defp increment(value, :bit8) when value < 0x7F, do: {value + 1, false, false}
    defp increment(0xFFFF, :bit16), do: {0, true, false}
    defp increment(value, :bit16) when value >= 0x7FFF, do: {value + 1, false, true}
    defp increment(value, :bit16) when value < 0x7FFF, do: {value + 1, false, false}

    def disasm(%{opcode: 0x1A}, _memory, _address), do: "INC A"

    def disasm(%{opcode: 0xEE}, memory, address) do
      addr = Memory.read_word(memory, address + 1)
      "INC #{BasicTypes.format_word(addr)}"
    end

    def disasm(%{opcode: 0xE6}, memory, address) do
      dp = Memory.read_byte(memory, address + 1)
      "INC #{BasicTypes.format_byte(dp)}"
    end

    def disasm(%{opcode: 0xFE}, memory, address) do
      addr = Memory.read_word(memory, address + 1)
      "INC #{BasicTypes.format_word(addr)},X"
    end

    def disasm(%{opcode: 0xF6}, memory, address) do
      dp = Memory.read_byte(memory, address + 1)
      "INC #{BasicTypes.format_byte(dp)},X"
    end
  end
end
