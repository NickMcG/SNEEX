defmodule Sneex.Address.DirectPage do
  @moduledoc """
  This module defines the behavior for accessing direct page memory.
  """
  alias Sneex.Address.Helper
  alias Sneex.{BasicTypes, Cpu}
  use Bitwise

  defstruct [:address, :fetch_cycles, :store_cycles]

  @type t :: %__MODULE__{address: BasicTypes.word(), fetch_cycles: 0 | 1, store_cycles: 0 | 1 | 2}

  @spec new(Sneex.Cpu.t()) :: __MODULE__.t()
  def new(cpu = %Cpu{}) do
    dp = cpu |> Cpu.direct_page()
    addr = cpu |> Cpu.read_operand(1) |> calc_addr(dp)
    dp_cycles = dp |> band(0x00FF) |> check_for_dp_cycles()
    size_cycles = cpu |> Cpu.acc_size() |> Helper.extra_cycle_for_16_bit()

    %__MODULE__{address: addr, fetch_cycles: size_cycles, store_cycles: dp_cycles + size_cycles}
  end

  defp calc_addr(op, dp), do: (op + dp) |> band(0xFFFF)

  defp check_for_dp_cycles(0), do: 0
  defp check_for_dp_cycles(_), do: 1

  defimpl Sneex.Address.Mode do
    def address(%{address: addr}), do: addr

    def byte_size(_mode), do: 1

    def fetch_cycles(%{fetch_cycles: cycles}), do: cycles

    def fetch(%{address: addr}, cpu), do: cpu |> Cpu.read_data(addr)

    def store_cycles(%{store_cycles: cycles}), do: cycles

    def store(%{address: addr}, cpu, data), do: cpu |> Cpu.write_data(addr, data)

    def disasm(_mode, cpu) do
      cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte()
    end
  end
end
