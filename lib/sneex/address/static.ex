defmodule Sneex.Address.Static do
  @moduledoc """
  This is a test address implementation.
  This is not expected to be used in actual code, but can be used for testing.
  Any data saved is saved to the accumulator.
  """
  alias Sneex.Cpu

  defstruct [:address, :size, :cycles, :data, :disasm]

  @type t :: %__MODULE__{address: any(), size: any(), cycles: any(), data: any(), disasm: any()}

  @spec new(any(), any(), any(), any(), any()) :: __MODULE__.t()
  def new(address, size, cycles, data, disasm) do
    %__MODULE__{address: address, size: size, cycles: cycles, data: data, disasm: disasm}
  end

  defimpl Sneex.Address.Mode do
    def address(%{address: addr}), do: addr

    def byte_size(%{size: size}), do: size

    def fetch_cycles(%{cycles: cycles}), do: cycles

    def fetch(%{data: data}, _cpu), do: data

    def store_cycles(%{cycles: cycles}), do: cycles

    def store(_mode, cpu, data), do: cpu |> Cpu.acc(data)

    def disasm(%{disasm: disasm}, _cpu), do: disasm
  end
end
