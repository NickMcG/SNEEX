defmodule Sneex.Address.Immediate do
  @moduledoc "
  This module defines the implementation for immediate addressing
  "
  alias Sneex.{BasicTypes, Cpu}
  use Bitwise
  defstruct [:byte_size]

  @type t :: %__MODULE__{byte_size: 1 | 2}

  @spec new(Cpu.t()) :: __MODULE__.t()
  def new(cpu = %Cpu{}) do
    %__MODULE__{byte_size: cpu |> Cpu.acc_size() |> calc_byte_size()}
  end

  defp calc_byte_size(:bit8), do: 1
  defp calc_byte_size(:bit16), do: 2

  defimpl Sneex.Address.Mode do
    def address(_mode), do: 0

    def byte_size(%{byte_size: size}), do: size

    def fetch(%{byte_size: size}, cpu), do: cpu |> Cpu.read_operand(size)

    def store(_mode, cpu, _data), do: cpu

    def disasm(%{byte_size: 1}, cpu),
      do: cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte() |> format_data()

    def disasm(%{byte_size: 2}, cpu),
      do: cpu |> Cpu.read_operand(2) |> BasicTypes.format_word() |> format_data()

    defp format_data(data), do: "##{data}"
  end
end
