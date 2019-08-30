defmodule Sneex.AddressMode do
  @moduledoc """
  This module contains the logic for converting an address offset into a full address
  using the current state of the CPU and the logic for each addressing mode.
  """
  alias Sneex.{BasicTypes, Cpu}
  use Bitwise

  @typep word :: BasicTypes.word()
  @typep long :: BasicTypes.long()

  @spec absolute(Cpu.t(), boolean(), word()) :: long()
  def absolute(cpu = %Cpu{}, _data_address? = true, address_offset) do
    cpu |> Cpu.data_bank() |> absolute(address_offset)
  end

  def absolute(cpu = %Cpu{}, _data_address? = false, address_offset) do
    cpu |> Cpu.program_bank() |> absolute(address_offset)
  end

  defp absolute(upper_byte, addr), do: upper_byte |> bsl(16) |> bor(addr)

  @spec absolute_indexed_x(Cpu.t(), word()) :: long()
  def absolute_indexed_x(cpu = %Cpu{}, address_offset) do
    addr = absolute(cpu, true, address_offset) + Cpu.x(cpu)
    addr |> band(0xFFFFFF)
  end

  @spec absolute_indexed_y(Cpu.t(), word()) :: long()
  def absolute_indexed_y(cpu = %Cpu{}, address_offset) do
    addr = absolute(cpu, true, address_offset) + Cpu.y(cpu)
    addr |> band(0xFFFFFF)
  end

  @spec absolute_indexed_indirect(Cpu.t()) :: long()
  def absolute_indexed_indirect(cpu = %Cpu{}) do
    pbr = cpu |> Cpu.program_bank() |> bsl(16)
    operand = cpu |> Cpu.read_operand(2)
    x = cpu |> Cpu.x()
    indirect_addr = (pbr + operand + x) |> band(0xFFFFFF)

    addr = cpu |> Cpu.read_data(indirect_addr, 2)
    (pbr + addr) |> band(0xFFFFFF)
  end

  @spec absolute_indirect(Cpu.t()) :: long()
  def absolute_indirect(cpu = %Cpu{}) do
    pbr = cpu |> Cpu.program_bank() |> bsl(16)
    indirect_addr = cpu |> Cpu.read_operand(2)

    addr = cpu |> Cpu.read_data(indirect_addr, 2)
    (pbr + addr) |> band(0xFFFFFF)
  end

  @spec absolute_indirect_long(Cpu.t()) :: long()
  def absolute_indirect_long(cpu = %Cpu{}) do
    indirect_addr = cpu |> Cpu.read_operand(2)

    cpu |> Cpu.read_data(indirect_addr, 3)
  end

  @spec absolute_long(Cpu.t()) :: long()
  def absolute_long(cpu = %Cpu{}) do
    cpu |> Cpu.read_operand(3)
  end

  @spec absolute_long_indexed_x(Cpu.t()) :: long()
  def absolute_long_indexed_x(cpu = %Cpu{}) do
    base = cpu |> Cpu.read_operand(3)
    x = cpu |> Cpu.x()
    (base + x) |> band(0xFFFFFF)
  end

  @spec block_move(Cpu.t()) :: {long(), long(), long()}
  def block_move(cpu = %Cpu{}) do
    operand = cpu |> Cpu.read_operand(2)

    src_bank = operand |> band(0xFF00) |> bsl(8)
    src_addr = src_bank + Cpu.x(cpu)

    dst_bank = operand |> band(0x00FF) |> bsl(16)
    dst_addr = dst_bank + Cpu.y(cpu)

    {src_addr, dst_addr, Cpu.c(cpu) + 1}
  end

  @spec direct_page(Cpu.t(), word()) :: long()
  def direct_page(cpu = %Cpu{}, address_offset) do
    dpr = Cpu.direct_page(cpu)
    (dpr + address_offset) |> band(0x00FFFF)
  end

  @spec direct_page_indexed_x(Cpu.t(), word()) :: long()
  def direct_page_indexed_x(cpu = %Cpu{}, address_offset) do
    x = Cpu.x(cpu)
    direct_page(cpu, address_offset + x)
  end

  @spec direct_page_indexed_y(Cpu.t(), word()) :: long()
  def direct_page_indexed_y(cpu = %Cpu{}, address_offset) do
    y = Cpu.y(cpu)
    direct_page(cpu, address_offset + y)
  end

  @spec direct_page_indexed_indirect(Cpu.t()) :: long()
  def direct_page_indexed_indirect(cpu = %Cpu{}) do
    dbr = cpu |> Cpu.data_bank() |> bsl(16)
    x = cpu |> Cpu.x()
    dpr = cpu |> Cpu.direct_page()
    operand = cpu |> Cpu.read_operand(1)
    indirect_addr = (dpr + operand + x) |> band(0xFFFF)

    addr = cpu |> Cpu.read_data(indirect_addr, 2)
    (dbr + addr) |> band(0xFFFFFF)
  end

  @spec direct_page_indirect(Cpu.t()) :: long()
  def direct_page_indirect(cpu = %Cpu{}) do
    dbr = cpu |> Cpu.data_bank() |> bsl(16)
    dpr = cpu |> Cpu.direct_page()
    operand = cpu |> Cpu.read_operand(1)
    indirect_addr = (dpr + operand) |> band(0xFFFF)

    addr = cpu |> Cpu.read_data(indirect_addr, 2)
    (dbr + addr) |> band(0xFFFFFF)
  end

  @spec direct_page_indirect_long(Cpu.t()) :: long()
  def direct_page_indirect_long(cpu = %Cpu{}) do
    dpr = cpu |> Cpu.direct_page()
    operand = cpu |> Cpu.read_operand(1)
    indirect_addr = (dpr + operand) |> band(0xFFFF)

    cpu |> Cpu.read_data(indirect_addr, 3)
  end

  @spec direct_page_indirect_indexed_y(Cpu.t()) :: long()
  def direct_page_indirect_indexed_y(cpu = %Cpu{}) do
    dpr = cpu |> Cpu.direct_page()
    operand = cpu |> Cpu.read_operand(1)
    indirect_addr = (dpr + operand) |> band(0xFFFF)

    y = cpu |> Cpu.y()
    dbr = cpu |> Cpu.data_bank() |> bsl(16)
    base_addr = cpu |> Cpu.read_data(indirect_addr, 2)

    (dbr + base_addr + y) |> band(0xFFFFFF)
  end

  @spec direct_page_indirect_long_indexed_y(Cpu.t()) :: long()
  def direct_page_indirect_long_indexed_y(cpu = %Cpu{}) do
    dpr = cpu |> Cpu.direct_page()
    operand = cpu |> Cpu.read_operand(1)
    indirect_addr = (dpr + operand) |> band(0xFFFF)

    y = cpu |> Cpu.y()
    base_addr = cpu |> Cpu.read_data(indirect_addr, 3)

    (base_addr + y) |> band(0xFFFFFF)
  end

  @spec program_counter_relative(Cpu.t()) :: long()
  def program_counter_relative(cpu = %Cpu{}) do
    pbr = cpu |> Cpu.program_bank() |> bsl(16)
    operand = cpu |> Cpu.read_operand(1) |> BasicTypes.signed_byte()
    pc = cpu |> Cpu.pc()

    pbr + ((pc + 2 + operand) |> band(0xFFFFFF))
  end

  @spec program_counter_relative_long(Cpu.t()) :: long()
  def program_counter_relative_long(cpu = %Cpu{}) do
    pbr = cpu |> Cpu.program_bank() |> bsl(16)
    operand = cpu |> Cpu.read_operand(2) |> BasicTypes.signed_word()
    pc = cpu |> Cpu.pc()

    pbr + ((pc + 3 + operand) |> band(0xFFFFFF))
  end

  # Still need to support the 13 or so stack-based addressing modes
end
