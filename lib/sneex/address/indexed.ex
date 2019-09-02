defmodule Sneex.Address.Indexed do
  @moduledoc """
  This is an address modifier that can be used to adjust an address based off of
  one of the index registers (X or Y).
  """
  alias Sneex.Address.Mode
  alias Sneex.Cpu

  defstruct [:base_mode, :address, :register]

  @type t :: %__MODULE__{base_mode: any(), address: integer(), register: index_registers()}
  @type index_registers :: :x | :y

  @spec new(any(), Sneex.Cpu.t(), index_registers()) :: __MODULE__.t()
  def new(base, cpu = %Cpu{}, register) do
    address = base |> Mode.address() |> adjust_address(cpu, register)
    %__MODULE__{base_mode: base, address: address, register: register}
  end

  defp adjust_address(address, cpu, :x), do: address + Cpu.x(cpu)
  defp adjust_address(address, cpu, :y), do: address + Cpu.y(cpu)

  defimpl Sneex.Address.Mode do
    def address(%{address: address}), do: address

    def byte_size(%{base_mode: mode}), do: Mode.byte_size(mode)

    def fetch_cycles(%{base_mode: base}), do: Mode.fetch_cycles(base)

    def fetch(%{address: addr}, cpu), do: cpu |> Cpu.read_data(addr)

    def store_cycles(%{base_mode: base}), do: Mode.store_cycles(base)

    def store(%{address: addr}, cpu, data), do: cpu |> Cpu.write_data(addr, data)

    def disasm(%{base_mode: mode, register: :x}, cpu), do: "#{Mode.disasm(mode, cpu)},X"
    def disasm(%{base_mode: mode, register: :y}, cpu), do: "#{Mode.disasm(mode, cpu)},Y"
  end
end
