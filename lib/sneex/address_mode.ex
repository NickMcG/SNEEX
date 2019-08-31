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
  def absolute(cpu = %Cpu{}, _data? = true, address_offset),
    do: cpu |> Cpu.data_bank() |> absolute_offset(address_offset)

  def absolute(cpu = %Cpu{}, _data? = false, address_offset),
    do: cpu |> Cpu.program_bank() |> absolute_offset(address_offset)

  @spec absolute_indexed_x(Cpu.t(), word()) :: long()
  def absolute_indexed_x(cpu = %Cpu{}, offset),
    do: cpu |> absolute(true, offset) |> indexed(cpu, :x)

  @spec absolute_indexed_y(Cpu.t(), word()) :: long()
  def absolute_indexed_y(cpu = %Cpu{}, offset),
    do: cpu |> absolute(true, offset) |> indexed(cpu, :y)

  @spec absolute_indexed_indirect(Cpu.t()) :: long()
  def absolute_indexed_indirect(cpu = %Cpu{}) do
    pbr = cpu |> Cpu.program_bank()
    operand = cpu |> Cpu.read_operand(2)
    addr = pbr |> absolute_offset(operand) |> indexed(cpu, :x) |> read_indirect(cpu, 2)
    pbr |> absolute_offset(addr)
  end

  @spec absolute_indirect(Cpu.t()) :: long()
  def absolute_indirect(cpu = %Cpu{}) do
    addr = cpu |> Cpu.read_operand(2) |> read_indirect(cpu, 2)
    cpu |> Cpu.program_bank() |> absolute_offset(addr)
  end

  @spec absolute_indirect_long(Cpu.t()) :: long()
  def absolute_indirect_long(cpu = %Cpu{}),
    do: cpu |> Cpu.read_operand(2) |> read_indirect(cpu, 3)

  @spec absolute_long(Cpu.t()) :: long()
  def absolute_long(cpu = %Cpu{}), do: cpu |> Cpu.read_operand(3)

  @spec absolute_long_indexed_x(Cpu.t()) :: long()
  def absolute_long_indexed_x(cpu = %Cpu{}), do: cpu |> Cpu.read_operand(3) |> indexed(cpu, :x)

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
  def direct_page(cpu = %Cpu{}, address_offset),
    do: cpu |> Cpu.direct_page() |> calc_offset(address_offset)

  @spec direct_page_indexed_x(Cpu.t(), word()) :: long()
  def direct_page_indexed_x(cpu = %Cpu{}, address_offset),
    do: direct_page(cpu, address_offset + Cpu.x(cpu))

  @spec direct_page_indexed_y(Cpu.t(), word()) :: long()
  def direct_page_indexed_y(cpu = %Cpu{}, address_offset),
    do: direct_page(cpu, address_offset + Cpu.y(cpu))

  @spec direct_page_indexed_indirect(Cpu.t()) :: long()
  def direct_page_indexed_indirect(cpu = %Cpu{}) do
    temp_addr = Cpu.x(cpu) + Cpu.read_operand(cpu, 1)
    addr = cpu |> direct_page(temp_addr) |> read_indirect(cpu, 2)
    cpu |> Cpu.data_bank() |> absolute_offset(addr)
  end

  @spec direct_page_indirect(Cpu.t()) :: long()
  def direct_page_indirect(cpu = %Cpu{}) do
    operand = cpu |> Cpu.read_operand(1)
    addr = cpu |> direct_page(operand) |> read_indirect(cpu, 2)
    cpu |> Cpu.data_bank() |> absolute_offset(addr)
  end

  @spec direct_page_indirect_long(Cpu.t()) :: long()
  def direct_page_indirect_long(cpu = %Cpu{}) do
    operand = cpu |> Cpu.read_operand(1)
    cpu |> direct_page(operand) |> read_indirect(cpu, 3)
  end

  @spec direct_page_indirect_indexed_y(Cpu.t()) :: long()
  def direct_page_indirect_indexed_y(cpu = %Cpu{}) do
    operand = cpu |> Cpu.read_operand(1)
    base_addr = cpu |> direct_page(operand) |> read_indirect(cpu, 2)
    cpu |> Cpu.data_bank() |> absolute_offset(base_addr) |> indexed(cpu, :y)
  end

  @spec direct_page_indirect_long_indexed_y(Cpu.t()) :: long()
  def direct_page_indirect_long_indexed_y(cpu = %Cpu{}) do
    operand = cpu |> Cpu.read_operand(1)
    cpu |> direct_page(operand) |> read_indirect(cpu, 3) |> indexed(cpu, :y)
  end

  defp program_counter(cpu = %Cpu{}, offset) do
    pc_with_offset = cpu |> Cpu.pc() |> calc_offset(offset)
    cpu |> Cpu.program_bank() |> absolute_offset(pc_with_offset)
  end

  @spec program_counter_relative(Cpu.t()) :: long()
  def program_counter_relative(cpu = %Cpu{}) do
    operand = cpu |> Cpu.read_operand(1) |> BasicTypes.signed_byte()
    cpu |> program_counter(operand + 2)
  end

  @spec program_counter_relative_long(Cpu.t()) :: long()
  def program_counter_relative_long(cpu = %Cpu{}) do
    operand = cpu |> Cpu.read_operand(2) |> BasicTypes.signed_word()
    cpu |> program_counter(operand + 3)
  end

  @spec stack_relative(Cpu.t()) :: long()
  def stack_relative(cpu = %Cpu{}) do
    operand = cpu |> Cpu.read_operand(1)
    cpu |> Cpu.stack_ptr() |> calc_offset(operand)
  end

  @spec stack_relative_indirect_indexed_y(Cpu.t()) :: long()
  def stack_relative_indirect_indexed_y(cpu = %Cpu{}) do
    offset = cpu |> stack_relative() |> read_indirect(cpu, 2)
    cpu |> Cpu.data_bank() |> absolute_offset(offset) |> indexed(cpu, :y)
  end

  defp indexed(addr, cpu = %Cpu{}, :x), do: (addr + Cpu.x(cpu)) |> band(0xFFFFFF)
  defp indexed(addr, cpu = %Cpu{}, :y), do: (addr + Cpu.y(cpu)) |> band(0xFFFFFF)

  defp calc_offset(part1, part2), do: (part1 + part2) |> band(0xFFFF)

  defp absolute_offset(upper_byte, addr), do: upper_byte |> bsl(16) |> bor(addr) |> band(0xFFFFFF)

  defp read_indirect(addr, cpu = %Cpu{}, size), do: cpu |> Cpu.read_data(addr, size)
end
