defmodule Sneex.Address.DirectPage do
  @moduledoc """
  This module defines the behavior for accessing direct page memory.
  """
  alias Sneex.{BasicTypes, Cpu}
  use Bitwise

  defstruct [:address]

  @type t :: %__MODULE__{address: BasicTypes.word()}

  @spec new(Sneex.Cpu.t()) :: __MODULE__.t()
  def new(cpu = %Cpu{}) do
    dp = cpu |> Cpu.direct_page()
    addr = cpu |> Cpu.read_operand(1) |> calc_addr(dp)

    %__MODULE__{address: addr}
  end

  defp calc_addr(op, dp), do: (op + dp) |> band(0xFFFF)

  defimpl Sneex.Address.Mode do
    def address(%{address: addr}, _cpu), do: addr

    def byte_size(_mode, _cpu), do: 1

    def fetch(%{address: addr}, cpu), do: cpu |> Cpu.read_data(addr)

    def store(%{address: addr}, cpu, data), do: cpu |> Cpu.write_data(addr, data)

    def disasm(_mode, cpu) do
      cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte()
    end
  end
end
