defmodule Sneex.AddressMode do
  @moduledoc """
  This module contains the logic for converting an address offset into a full address
  using the current state of the CPU and the logic for each addressing mode.
  """
  alias Sneex.Cpu
  use Bitwise

  @typep word :: Sneex.BasicTypes.word()
  @typep long :: Sneex.BasicTypes.long()

  @spec absolute(Sneex.Cpu.t(), word()) :: long()
  def absolute(cpu = %Cpu{}, address_offset) do
    cpu |> Cpu.data_bank() |> bsl(16) |> bor(address_offset)
  end

  @spec direct_page(Sneex.Cpu.t(), word()) :: long()
  def direct_page(cpu = %Cpu{}, address_offset) do
    dpr = Cpu.direct_page(cpu)
    (dpr + address_offset) |> band(0x00FFFF)
  end

  @spec absolute_indexed_x(Sneex.Cpu.t(), word()) :: long()
  def absolute_indexed_x(cpu = %Cpu{}, address_offset) do
    addr = absolute(cpu, address_offset) + Cpu.x(cpu)
    addr |> band(0xFFFFFF)
  end

  @spec direct_page_indexed_x(Sneex.Cpu.t(), word()) :: long()
  def direct_page_indexed_x(cpu = %Cpu{}, address_offset) do
    x = Cpu.x(cpu)
    direct_page(cpu, address_offset + x)
  end
end
