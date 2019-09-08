defmodule Sneex.Address.Absolute do
  @moduledoc """
  This module defines the implementation for absolute addressing
  """
  alias Sneex.{BasicTypes, Cpu}
  use Bitwise
  defstruct [:address]

  @type t :: %__MODULE__{address: BasicTypes.word()}

  @spec new(Cpu.t(), boolean()) :: __MODULE__.t()
  def new(cpu = %Cpu{}, is_data?) do
    addr = is_data? |> calc_addr(cpu)

    %__MODULE__{address: addr}
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

    def disasm(_mode, cpu) do
      cpu |> Cpu.read_operand(2) |> BasicTypes.format_word()
    end
  end
end
