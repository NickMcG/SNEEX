defmodule Sneex.Address.Absolute do
  @moduledoc """
  This module defines the implementation for absolute addressing
  """
  alias Sneex.Address.Helper
  alias Sneex.{BasicTypes, Cpu}
  defstruct [:address, :extra_cycles]

  @type t :: %__MODULE__{address: BasicTypes.word(), extra_cycles: 0 | 1}

  @spec new(Cpu.t(), boolean()) :: __MODULE__.t()
  def new(cpu = %Cpu{}, is_data?) do
    addr = is_data? |> calc_addr(cpu)
    cycles = cpu |> Cpu.acc_size() |> Helper.extra_cycle_for_16_bit()

    %__MODULE__{address: addr, extra_cycles: cycles}
  end

  defp calc_addr(_is_data? = true, cpu), do: cpu |> Cpu.data_bank() |> calc_addr(cpu)
  defp calc_addr(_is_data? = false, cpu), do: cpu |> Cpu.program_bank() |> calc_addr(cpu)

  defp calc_addr(bank, cpu) do
    operand = cpu |> Cpu.read_operand(2)
    bank |> Helper.absolute_offset(operand)
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
