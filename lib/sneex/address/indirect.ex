defmodule Sneex.Address.Indirect do
  @moduledoc "
  This module defines the implementation for indirect addressing
  "
  alias Sneex.Address.Mode
  alias Sneex.Cpu
  use Bitwise
  defstruct [:base_mode, :address, :is_long?]

  @type t :: %__MODULE__{base_mode: any(), address: integer(), is_long?: boolean()}

  @spec new_data(any(), Cpu.t()) :: __MODULE__.t()
  def new_data(base, cpu = %Cpu{}), do: cpu |> Cpu.data_bank() |> new(base, cpu)

  @spec new_program(any(), Cpu.t()) :: __MODULE__.t()
  def new_program(base, cpu = %Cpu{}), do: cpu |> Cpu.program_bank() |> new(base, cpu)

  @spec new_long(any(), Cpu.t()) :: __MODULE__.t()
  def new_long(base, cpu = %Cpu{}) do
    base_addr = base |> Mode.address(cpu)
    addr = cpu |> Cpu.read_data(base_addr, 3)
    %__MODULE__{base_mode: base, address: addr, is_long?: true}
  end

  defp new(bank, base, cpu = %Cpu{}) do
    base_addr = base |> Mode.address(cpu)
    data = cpu |> Cpu.read_data(base_addr, 2)
    addr = bank |> calc_addr(data)
    %__MODULE__{base_mode: base, address: addr, is_long?: false}
  end

  defp calc_addr(bank, addr), do: bank |> bsl(16) |> bor(addr) |> band(0xFFFFFF)

  defimpl Sneex.Address.Mode do
    def address(%{address: addr}, _cpu), do: addr

    def byte_size(%{base_mode: mode}, cpu), do: Mode.byte_size(mode, cpu)

    def fetch(%{address: addr}, cpu), do: cpu |> Cpu.read_data(addr)

    def store(%{address: addr}, cpu, data), do: cpu |> Cpu.write_data(addr, data)

    def disasm(%{base_mode: mode, is_long?: false}, cpu), do: "(#{Mode.disasm(mode, cpu)})"
    def disasm(%{base_mode: mode, is_long?: true}, cpu), do: "[#{Mode.disasm(mode, cpu)}]"
  end
end
