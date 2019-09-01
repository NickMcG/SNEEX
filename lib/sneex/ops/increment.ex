defmodule Sneex.Ops.Increment do
  @moduledoc """
  This represents the op codes for incrementing a value (INC, INX, and INY).
  """
  defstruct [:opcode]

  alias Sneex.{AddressMode, BasicTypes, Cpu}

  @opaque t :: %__MODULE__{opcode: 0x1A | 0xEE | 0xE6 | 0xFE | 0xF6 | 0xE8 | 0xC8}

  @spec new(byte()) :: nil | __MODULE__.t()

  def new(0x1A), do: %__MODULE__{opcode: 0x1A}
  def new(0xEE), do: %__MODULE__{opcode: 0xEE}
  def new(0xE6), do: %__MODULE__{opcode: 0xE6}
  def new(0xFE), do: %__MODULE__{opcode: 0xFE}
  def new(0xF6), do: %__MODULE__{opcode: 0xF6}
  def new(0xE8), do: %__MODULE__{opcode: 0xE8}
  def new(0xC8), do: %__MODULE__{opcode: 0xC8}

  def new(_opcode), do: nil

  defimpl Sneex.Ops.Opcode do
    def byte_size(%{opcode: 0x1A}, _cpu), do: 1
    def byte_size(%{opcode: 0xEE}, _cpu), do: 3
    def byte_size(%{opcode: 0xE6}, _cpu), do: 2
    def byte_size(%{opcode: 0xFE}, _cpu), do: 3
    def byte_size(%{opcode: 0xF6}, _cpu), do: 2
    def byte_size(%{opcode: 0xE8}, _cpu), do: 1
    def byte_size(%{opcode: 0xC8}, _cpu), do: 1

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

    def total_cycles(%{opcode: 0xE8}, _cpu), do: 2

    def total_cycles(%{opcode: 0xC8}, _cpu), do: 2

    defp add_16_bit_cycles(:bit8), do: 0
    defp add_16_bit_cycles(_status), do: 2

    defp add_direct_page_cycles(0x00), do: 0
    defp add_direct_page_cycles(_), do: 1

    def execute(%{opcode: 0x1A}, cpu) do
      {new_a, cpu} = cpu |> Cpu.acc() |> increment(cpu)
      cpu |> Cpu.acc(new_a)
    end

    def execute(%{opcode: 0xEE}, cpu) do
      operand = Cpu.read_operand(cpu, 2)
      cpu |> AddressMode.absolute(true, operand) |> increment_from_address(cpu)
    end

    def execute(%{opcode: 0xE6}, cpu) do
      operand = Cpu.read_operand(cpu, 1)
      cpu |> AddressMode.direct_page(operand) |> increment_from_address(cpu)
    end

    def execute(%{opcode: 0xFE}, cpu) do
      operand = Cpu.read_operand(cpu, 2)
      cpu |> AddressMode.absolute_indexed_x(operand) |> increment_from_address(cpu)
    end

    def execute(%{opcode: 0xF6}, cpu) do
      operand = Cpu.read_operand(cpu, 1)
      cpu |> AddressMode.direct_page_indexed_x(operand) |> increment_from_address(cpu)
    end

    def execute(%{opcode: 0xE8}, cpu) do
      x = Cpu.x(cpu)
      {new_x, cpu} = cpu |> Cpu.index_size() |> increment(x, cpu)
      cpu |> Cpu.x(new_x)
    end

    def execute(%{opcode: 0xC8}, cpu) do
      y = Cpu.y(cpu)
      {new_y, cpu} = cpu |> Cpu.index_size() |> increment(y, cpu)
      cpu |> Cpu.y(new_y)
    end

    defp increment_from_address(address, cpu = %Cpu{}) do
      data = Cpu.read_data(cpu, address)
      {new_value, cpu} = increment(data, cpu)
      Cpu.write_data(cpu, address, new_value)
    end

    defp increment(bitness, value, cpu = %Cpu{}) do
      {new_value, zf, nf} = increment(value, bitness)

      new_cpu = cpu |> Cpu.zero_flag(zf) |> Cpu.negative_flag(nf)
      {new_value, new_cpu}
    end

    defp increment(value, cpu = %Cpu{}) do
      cpu |> Cpu.acc_size() |> increment(value, cpu)
    end

    defp increment(0xFF, :bit8), do: {0, true, false}
    defp increment(value, :bit8) when value >= 0x7F, do: {value + 1, false, true}
    defp increment(value, :bit8) when value < 0x7F, do: {value + 1, false, false}
    defp increment(0xFFFF, :bit16), do: {0, true, false}
    defp increment(value, :bit16) when value >= 0x7FFF, do: {value + 1, false, true}
    defp increment(value, :bit16) when value < 0x7FFF, do: {value + 1, false, false}

    def disasm(%{opcode: 0x1A}, _cpu), do: "INC A"

    def disasm(%{opcode: 0xEE}, cpu) do
      data = cpu |> Cpu.read_operand(2) |> BasicTypes.format_word()
      "INC #{data}"
    end

    def disasm(%{opcode: 0xE6}, cpu) do
      dp = cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte()
      "INC #{dp}"
    end

    def disasm(%{opcode: 0xFE}, cpu) do
      data = cpu |> Cpu.read_operand(2) |> BasicTypes.format_word()
      "INC #{data},X"
    end

    def disasm(%{opcode: 0xF6}, cpu) do
      dp = cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte()
      "INC #{dp},X"
    end

    def disasm(%{opcode: 0xE8}, _cpu), do: "INX"

    def disasm(%{opcode: 0xC8}, _cpu), do: "INY"
  end
end
