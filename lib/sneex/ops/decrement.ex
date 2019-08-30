defmodule Sneex.Ops.Decrement do
  @moduledoc """
  This represents the op codes for decrementing a value (DEC, DEX, and DEY).
  """
  defstruct [:opcode]

  alias Sneex.{AddressMode, BasicTypes, Cpu, Memory}

  @opaque t :: %__MODULE__{opcode: 0x3A | 0xCE | 0xC6 | 0xDE | 0xD6 | 0xCA | 0x88}

  @spec new(byte()) :: nil | __MODULE__.t()

  def new(0x3A), do: %__MODULE__{opcode: 0x3A}
  def new(0xCE), do: %__MODULE__{opcode: 0xCE}
  def new(0xC6), do: %__MODULE__{opcode: 0xC6}
  def new(0xDE), do: %__MODULE__{opcode: 0xDE}
  def new(0xD6), do: %__MODULE__{opcode: 0xD6}
  def new(0xCA), do: %__MODULE__{opcode: 0xCA}
  def new(0x88), do: %__MODULE__{opcode: 0x88}

  def new(_opcode), do: nil

  defimpl Sneex.Ops.Opcode do
    def byte_size(%{opcode: 0x3A}), do: 1
    def byte_size(%{opcode: 0xCE}), do: 3
    def byte_size(%{opcode: 0xC6}), do: 2
    def byte_size(%{opcode: 0xDE}), do: 3
    def byte_size(%{opcode: 0xD6}), do: 2
    def byte_size(%{opcode: 0xCA}), do: 1
    def byte_size(%{opcode: 0x88}), do: 1

    def total_cycles(%{opcode: 0x3A}, _cpu), do: 2

    def total_cycles(%{opcode: 0xCE}, cpu) do
      status_cycles = cpu |> Cpu.acc_size() |> add_16_bit_cycles()
      6 + status_cycles
    end

    def total_cycles(%{opcode: 0xC6}, cpu) do
      status_cycles = cpu |> Cpu.acc_size() |> add_16_bit_cycles()
      page_cycles = cpu |> Cpu.direct_page() |> add_direct_page_cycles()
      5 + status_cycles + page_cycles
    end

    def total_cycles(%{opcode: 0xDE}, cpu) do
      status_cycles = cpu |> Cpu.acc_size() |> add_16_bit_cycles()
      7 + status_cycles
    end

    def total_cycles(%{opcode: 0xD6}, cpu) do
      status_cycles = cpu |> Cpu.acc_size() |> add_16_bit_cycles()
      page_cycles = cpu |> Cpu.direct_page() |> add_direct_page_cycles()
      6 + status_cycles + page_cycles
    end

    def total_cycles(%{opcode: 0xCA}, _cpu), do: 2

    def total_cycles(%{opcode: 0x88}, _cpu), do: 2

    defp add_16_bit_cycles(:bit8), do: 0
    defp add_16_bit_cycles(_status), do: 2

    defp add_direct_page_cycles(0x00), do: 0
    defp add_direct_page_cycles(_), do: 1

    def execute(%{opcode: 0x3A}, cpu) do
      {new_a, cpu} = cpu |> Cpu.acc() |> decrement(cpu)
      cpu |> Cpu.acc(new_a)
    end

    def execute(%{opcode: 0xCE}, cpu) do
      operand = Cpu.read_operand(cpu, 2)
      cpu |> AddressMode.absolute(true, operand) |> decrement_from_address(cpu)
    end

    def execute(%{opcode: 0xC6}, cpu) do
      operand = Cpu.read_operand(cpu, 1)
      cpu |> AddressMode.direct_page(operand) |> decrement_from_address(cpu)
    end

    def execute(%{opcode: 0xDE}, cpu) do
      operand = Cpu.read_operand(cpu, 2)
      cpu |> AddressMode.absolute_indexed_x(operand) |> decrement_from_address(cpu)
    end

    def execute(%{opcode: 0xD6}, cpu) do
      operand = Cpu.read_operand(cpu, 1)
      cpu |> AddressMode.direct_page_indexed_x(operand) |> decrement_from_address(cpu)
    end

    def execute(%{opcode: 0xCA}, cpu) do
      x = Cpu.x(cpu)
      {new_x, cpu} = cpu |> Cpu.index_size() |> decrement(x, cpu)
      cpu |> Cpu.x(new_x)
    end

    def execute(%{opcode: 0x88}, cpu) do
      y = Cpu.y(cpu)
      {new_y, cpu} = cpu |> Cpu.index_size() |> decrement(y, cpu)
      cpu |> Cpu.y(new_y)
    end

    defp decrement_from_address(address, cpu = %Cpu{}) do
      data = Cpu.read_data(cpu, address)
      {new_value, cpu} = decrement(data, cpu)
      Cpu.write_data(cpu, address, new_value)
    end

    defp decrement(bitness, value, cpu = %Cpu{}) do
      {new_value, zf, nf} = decrement(value, bitness)

      new_cpu = cpu |> Cpu.zero_flag(zf) |> Cpu.negative_flag(nf)
      {new_value, new_cpu}
    end

    defp decrement(value, cpu = %Cpu{}) do
      cpu |> Cpu.acc_size() |> decrement(value, cpu)
    end

    defp decrement(0x00, :bit8), do: {0xFF, false, true}
    defp decrement(0x01, :bit8), do: {0x00, true, false}
    defp decrement(value, :bit8) when value > 0x80, do: {value - 1, false, true}
    defp decrement(value, :bit8) when value <= 0x80, do: {value - 1, false, false}
    defp decrement(0x0000, :bit16), do: {0xFFFF, false, true}
    defp decrement(0x0001, :bit16), do: {0x0000, true, false}
    defp decrement(value, :bit16) when value > 0x8000, do: {value - 1, false, true}
    defp decrement(value, :bit16) when value <= 0x8000, do: {value - 1, false, false}

    def disasm(%{opcode: 0x3A}, _memory, _address), do: "DEC A"

    def disasm(%{opcode: 0xCE}, memory, address) do
      addr = Memory.read_word(memory, address + 1)
      "DEC #{BasicTypes.format_word(addr)}"
    end

    def disasm(%{opcode: 0xC6}, memory, address) do
      dp = Memory.read_byte(memory, address + 1)
      "DEC #{BasicTypes.format_byte(dp)}"
    end

    def disasm(%{opcode: 0xDE}, memory, address) do
      addr = Memory.read_word(memory, address + 1)
      "DEC #{BasicTypes.format_word(addr)},X"
    end

    def disasm(%{opcode: 0xD6}, memory, address) do
      dp = Memory.read_byte(memory, address + 1)
      "DEC #{BasicTypes.format_byte(dp)},X"
    end

    def disasm(%{opcode: 0xCA}, _memory, _address), do: "DEX"

    def disasm(%{opcode: 0x88}, _memory, _address), do: "DEY"
  end
end
