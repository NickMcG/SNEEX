defmodule Sneex.Ops.Increment do
  @moduledoc """
  This represents the op codes for incrementing a value (INC, INX, and INY).
  """
  defstruct [:opcode, :bit_size, :base_cycles, :address_mode]

  alias Sneex.Address.{Absolute, DirectPage, Indexed, Mode, Register}
  alias Sneex.Cpu

  @type t :: %__MODULE__{
          opcode: 0x1A | 0xEE | 0xE6 | 0xFE | 0xF6 | 0xE8 | 0xC8,
          bit_size: :bit8 | :bit16,
          base_cycles: pos_integer(),
          address_mode: any()
        }

  @spec new(byte(), Cpu.t()) :: nil | __MODULE__.t()

  # Maybe the new() signature should just take CPU?
  # And, maybe CPU should have a function that returns the opcode at the program counter?

  def new(0x1A, cpu) do
    addr_mode = :acc |> Register.new()
    bit_size = cpu |> Cpu.acc_size()
    %__MODULE__{opcode: 0x1A, bit_size: bit_size, base_cycles: 2, address_mode: addr_mode}
  end

  def new(0xEE, cpu) do
    addr_mode = cpu |> Absolute.new(true)
    bit_size = cpu |> Cpu.acc_size()
    %__MODULE__{opcode: 0xEE, bit_size: bit_size, base_cycles: 6, address_mode: addr_mode}
  end

  def new(0xE6, cpu) do
    addr_mode = cpu |> DirectPage.new()
    bit_size = cpu |> Cpu.acc_size()
    %__MODULE__{opcode: 0xE6, bit_size: bit_size, base_cycles: 5, address_mode: addr_mode}
  end

  def new(0xFE, cpu) do
    addr_mode = cpu |> Absolute.new(true) |> Indexed.new(cpu, :x)
    bit_size = cpu |> Cpu.acc_size()
    %__MODULE__{opcode: 0xFE, bit_size: bit_size, base_cycles: 7, address_mode: addr_mode}
  end

  def new(0xF6, cpu) do
    addr_mode = cpu |> DirectPage.new() |> Indexed.new(cpu, :x)
    bit_size = cpu |> Cpu.acc_size()
    %__MODULE__{opcode: 0xF6, bit_size: bit_size, base_cycles: 6, address_mode: addr_mode}
  end

  def new(0xE8, cpu) do
    addr_mode = Register.new(:x)
    bit_size = cpu |> Cpu.index_size()
    %__MODULE__{opcode: 0xE8, bit_size: bit_size, base_cycles: 2, address_mode: addr_mode}
  end

  def new(0xC8, cpu) do
    addr_mode = Register.new(:y)
    bit_size = cpu |> Cpu.index_size()
    %__MODULE__{opcode: 0xC8, bit_size: bit_size, base_cycles: 2, address_mode: addr_mode}
  end

  def new(_opcode, _cpu), do: nil

  defimpl Sneex.Ops.Opcode do
    def byte_size(%{address_mode: mode}, _cpu), do: 1 + Mode.byte_size(mode)

    def total_cycles(%{base_cycles: base, address_mode: mode}, _cpu) do
      base + Mode.fetch_cycles(mode) + Mode.store_cycles(mode)
    end

    def execute(%{address_mode: mode, bit_size: bit_size}, cpu) do
      {data, cpu} = mode |> Mode.fetch(cpu) |> increment(bit_size, cpu)
      mode |> Mode.store(cpu, data)
    end

    defp increment(value, bit_size, cpu = %Cpu{}) do
      {new_value, zf, nf} = bit_size |> increment(value)

      new_cpu = cpu |> Cpu.zero_flag(zf) |> Cpu.negative_flag(nf)
      {new_value, new_cpu}
    end

    defp increment(:bit8, 0xFF), do: {0, true, false}
    defp increment(:bit8, value) when value >= 0x7F, do: {value + 1, false, true}
    defp increment(:bit8, value) when value < 0x7F, do: {value + 1, false, false}
    defp increment(:bit16, 0xFFFF), do: {0, true, false}
    defp increment(:bit16, value) when value >= 0x7FFF, do: {value + 1, false, true}
    defp increment(:bit16, value) when value < 0x7FFF, do: {value + 1, false, false}

    def disasm(%{opcode: 0xE8}, _cpu), do: "INX"
    def disasm(%{opcode: 0xC8}, _cpu), do: "INY"
    def disasm(%{address_mode: mode}, cpu), do: "INC #{Mode.disasm(mode, cpu)}"
  end
end
