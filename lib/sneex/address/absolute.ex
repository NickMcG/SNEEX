defmodule Sneex.Address.Absolute do
  @moduledoc """
  This module defines the implementation for absolute addressing
  """
  defstruct [:address, :is_long?]

  alias Sneex.{BasicTypes, Cpu}
  use Bitwise

  @type t :: %__MODULE__{address: BasicTypes.word(), is_long?: boolean()}

  @spec new(Cpu.t(), boolean()) :: __MODULE__.t()
  def new(cpu = %Cpu{}, is_data?) do
    addr = is_data? |> calc_addr(cpu)

    %__MODULE__{address: addr, is_long?: false}
  end

  @spec new_long(Cpu.t()) :: __MODULE__.t()
  def new_long(cpu = %Cpu{}) do
    %__MODULE__{address: cpu |> Cpu.read_operand(3), is_long?: true}
  end

  defp calc_addr(_is_data? = true, cpu), do: cpu |> Cpu.data_bank() |> calc_addr(cpu)
  defp calc_addr(_is_data? = false, cpu), do: cpu |> Cpu.program_bank() |> calc_addr(cpu)

  defp calc_addr(bank, cpu) do
    operand = cpu |> Cpu.read_operand(2)
    bank |> bsl(16) |> bor(operand) |> band(0xFFFFFF)
  end

  defimpl Sneex.Address.Mode do
    def address(%{address: addr}), do: addr

    def byte_size(_mode), do: 2

    def fetch(%{address: addr}, cpu), do: cpu |> Cpu.read_data(addr)

    def store(%{address: addr}, cpu, data), do: cpu |> Cpu.write_data(addr, data)

    def disasm(%{address: a, is_long?: false}, _cpu),
      do: a |> band(0xFFFF) |> BasicTypes.format_word()

    def disasm(%{address: a, is_long?: true}, _cpu), do: a |> BasicTypes.format_long()
  end
end
