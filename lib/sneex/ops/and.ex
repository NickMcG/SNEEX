defmodule Sneex.Ops.And do
  @moduledoc """
  This module represents the AND operation.
  """
  defstruct [:opcode]

  use Bitwise
  alias Sneex.{AddressMode, BasicTypes, Cpu}

  @opaque t :: %__MODULE__{opcode: valid_code1() | valid_code2()}

  @typep valid_code1 :: 0x29 | 0x2D | 0x2F | 0x25 | 0x32 | 0x27 | 0x3D | 0x3F
  @typep valid_code2 :: 0x39 | 0x35 | 0x21 | 0x31 | 0x37 | 0x23 | 0x33

  @spec new(byte()) :: nil | __MODULE__.t()

  def new(oc) when oc == 0x29 or oc == 0x2D or oc == 0x2F, do: %__MODULE__{opcode: oc}
  def new(oc) when oc == 0x25 or oc == 0x32 or oc == 0x27, do: %__MODULE__{opcode: oc}
  def new(oc) when oc == 0x3D or oc == 0x3F or oc == 0x39, do: %__MODULE__{opcode: oc}
  def new(oc) when oc == 0x35 or oc == 0x21 or oc == 0x31, do: %__MODULE__{opcode: oc}
  def new(oc) when oc == 0x37 or oc == 0x23 or oc == 0x33, do: %__MODULE__{opcode: oc}
  def new(_opcode), do: nil

  defimpl Sneex.Ops.Opcode do
    @immediate 0x29
    @absolute 0x2D
    @absolute_long 0x2F
    @direct_page 0x25
    @direct_page_indirect 0x32
    @direct_page_indirect_long 0x27
    @absolute_indexed_x 0x3D
    @absolute_long_indexed_x 0x3F
    @absolute_indexed_y 0x39
    @direct_page_indexed_x 0x35

    # STILL NEED TO IMPLEMENT:
    # * DP Indexed Indirect, X
    # * DP Indirect Indexed, Y
    # * DP Indirect Long Indexed, Y
    # * Stack Relative (SR)
    # * SR Indirect Indexed, Y

    def byte_size(%{opcode: @immediate}, cpu) do
      bitness = cpu |> Cpu.acc_size()
      2 + add_one_for_16_bit(bitness)
    end

    def byte_size(%{opcode: @absolute}, _cpu), do: 3
    def byte_size(%{opcode: @absolute_long}, _cpu), do: 4
    def byte_size(%{opcode: @direct_page}, _cpu), do: 2
    def byte_size(%{opcode: @direct_page_indirect}, _cpu), do: 2
    def byte_size(%{opcode: @direct_page_indirect_long}, _cpu), do: 2
    def byte_size(%{opcode: @absolute_indexed_x}, _cpu), do: 3
    def byte_size(%{opcode: @absolute_long_indexed_x}, _cpu), do: 4
    def byte_size(%{opcode: @absolute_indexed_y}, _cpu), do: 3
    def byte_size(%{opcode: @direct_page_indexed_x}, _cpu), do: 2

    def total_cycles(%{opcode: @immediate}, cpu) do
      bitness = cpu |> Cpu.acc_size()
      2 + add_one_for_16_bit(bitness)
    end

    def total_cycles(%{opcode: @absolute}, cpu) do
      bitness = cpu |> Cpu.acc_size()
      4 + add_one_for_16_bit(bitness)
    end

    def total_cycles(%{opcode: @absolute_long}, cpu) do
      bitness = cpu |> Cpu.acc_size()
      5 + add_one_for_16_bit(bitness)
    end

    def total_cycles(%{opcode: @direct_page}, cpu) do
      bitness = cpu |> Cpu.acc_size() |> add_one_for_16_bit()
      dp = cpu |> Cpu.direct_page() |> add_one_for_direct_page()
      3 + bitness + dp
    end

    def total_cycles(%{opcode: @direct_page_indirect}, cpu) do
      bitness = cpu |> Cpu.acc_size() |> add_one_for_16_bit()
      dp = cpu |> Cpu.direct_page() |> add_one_for_direct_page()
      5 + bitness + dp
    end

    def total_cycles(%{opcode: @direct_page_indirect_long}, cpu) do
      bitness = cpu |> Cpu.acc_size() |> add_one_for_16_bit()
      dp = cpu |> Cpu.direct_page() |> add_one_for_direct_page()
      6 + bitness + dp
    end

    def total_cycles(%{opcode: @absolute_indexed_x}, cpu) do
      bitness = cpu |> Cpu.acc_size() |> add_one_for_16_bit()
      # ---- !!!!!!!!!!!!!!!!!! ----
      # Revisit this with the rewrite...
      page = add_one_for_crossing_page(0x00, 0x00)
      # ---- !!!!!!!!!!!!!!!!!! ----
      4 + bitness + page
    end

    def total_cycles(%{opcode: @absolute_long_indexed_x}, cpu) do
      bitness = cpu |> Cpu.acc_size() |> add_one_for_16_bit()
      5 + bitness
    end

    def total_cycles(%{opcode: @absolute_indexed_y}, cpu) do
      bitness = cpu |> Cpu.acc_size() |> add_one_for_16_bit()
      # ---- !!!!!!!!!!!!!!!!!! ----
      # Revisit this with the rewrite...
      page = add_one_for_crossing_page(0x00, 0x00)
      # ---- !!!!!!!!!!!!!!!!!! ----
      4 + bitness + page
    end

    def total_cycles(%{opcode: @direct_page_indexed_x}, cpu) do
      bitness = cpu |> Cpu.acc_size() |> add_one_for_16_bit()
      dp = cpu |> Cpu.direct_page() |> add_one_for_direct_page()
      4 + bitness + dp
    end

    defp add_one_for_16_bit(:bit16), do: 1
    defp add_one_for_16_bit(_), do: 0

    defp add_one_for_direct_page(dp) when 0x0000 == band(dp, 0xFF00), do: 0
    defp add_one_for_direct_page(_dp), do: 1

    defp add_one_for_crossing_page(addr1, addr2) when band(addr1, 0xFF00) == band(addr2, 0xFF00),
      do: 0

    defp add_one_for_crossing_page(_, _), do: 1

    def execute(%{opcode: @immediate}, cpu) do
      bitness = cpu |> Cpu.acc_size()
      bitness |> load_operand(cpu) |> process_and(cpu)
    end

    def execute(%{opcode: @absolute}, cpu) do
      operand = cpu |> Cpu.read_operand(2)
      addr = cpu |> AddressMode.absolute(true, operand)
      cpu |> Cpu.acc_size() |> load_data(cpu, addr) |> process_and(cpu)
    end

    def execute(%{opcode: @absolute_long}, cpu) do
      addr = cpu |> AddressMode.absolute_long()
      cpu |> Cpu.acc_size() |> load_data(cpu, addr) |> process_and(cpu)
    end

    def execute(%{opcode: @direct_page}, cpu) do
      operand = cpu |> Cpu.read_operand(1)
      addr = cpu |> AddressMode.direct_page(operand)
      cpu |> Cpu.acc_size() |> load_data(cpu, addr) |> process_and(cpu)
    end

    def execute(%{opcode: @direct_page_indirect}, cpu) do
      addr = cpu |> AddressMode.direct_page_indirect()
      cpu |> Cpu.acc_size() |> load_data(cpu, addr) |> process_and(cpu)
    end

    def execute(%{opcode: @direct_page_indirect_long}, cpu) do
      addr = cpu |> AddressMode.direct_page_indirect_long()
      cpu |> Cpu.acc_size() |> load_data(cpu, addr) |> process_and(cpu)
    end

    def execute(%{opcode: @absolute_indexed_x}, cpu) do
      operand = cpu |> Cpu.read_operand(2)
      addr = cpu |> AddressMode.absolute_indexed_x(operand)
      cpu |> Cpu.acc_size() |> load_data(cpu, addr) |> process_and(cpu)
    end

    def execute(%{opcode: @absolute_long_indexed_x}, cpu) do
      addr = cpu |> AddressMode.absolute_long_indexed_x()
      cpu |> Cpu.acc_size() |> load_data(cpu, addr) |> process_and(cpu)
    end

    def execute(%{opcode: @absolute_indexed_y}, cpu) do
      operand = cpu |> Cpu.read_operand(2)
      addr = cpu |> AddressMode.absolute_indexed_y(operand)
      cpu |> Cpu.acc_size() |> load_data(cpu, addr) |> process_and(cpu)
    end

    def execute(%{opcode: @direct_page_indexed_x}, cpu) do
      operand = cpu |> Cpu.read_operand(1)
      addr = cpu |> AddressMode.direct_page_indexed_x(operand)
      cpu |> Cpu.acc_size() |> load_data(cpu, addr) |> process_and(cpu)
    end

    def disasm(%{opcode: @immediate}, cpu) do
      case Cpu.acc_size(cpu) do
        :bit16 -> cpu |> Cpu.read_operand(2) |> BasicTypes.format_word() |> and_with_const()
        _ -> cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte() |> and_with_const()
      end
    end

    def disasm(%{opcode: @absolute}, cpu) do
      cpu |> Cpu.read_operand(2) |> BasicTypes.format_word() |> and_with_addr
    end

    def disasm(%{opcode: @absolute_long}, cpu) do
      cpu |> Cpu.read_operand(3) |> BasicTypes.format_long() |> and_with_addr
    end

    def disasm(%{opcode: @direct_page}, cpu) do
      cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte() |> and_with_addr
    end

    def disasm(%{opcode: @direct_page_indirect}, cpu) do
      addr = cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte()
      "AND (#{addr})"
    end

    def disasm(%{opcode: @direct_page_indirect_long}, cpu) do
      addr = cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte()
      "AND [#{addr}]"
    end

    def disasm(%{opcode: @absolute_indexed_x}, cpu) do
      addr = cpu |> Cpu.read_operand(2) |> BasicTypes.format_word()
      "AND #{addr}, X"
    end

    def disasm(%{opcode: @absolute_long_indexed_x}, cpu) do
      addr = cpu |> Cpu.read_operand(3) |> BasicTypes.format_long()
      "AND #{addr}, X"
    end

    def disasm(%{opcode: @absolute_indexed_y}, cpu) do
      addr = cpu |> Cpu.read_operand(2) |> BasicTypes.format_word()
      "AND #{addr}, Y"
    end

    def disasm(%{opcode: @direct_page_indexed_x}, cpu) do
      addr = cpu |> Cpu.read_operand(1) |> BasicTypes.format_byte()
      "AND #{addr}, X"
    end

    defp and_with_const(const), do: "AND ##{const}"
    defp and_with_addr(addr), do: "AND #{addr}"

    defp load_operand(:bit16, cpu), do: cpu |> Cpu.read_operand(2)
    defp load_operand(_, cpu), do: cpu |> Cpu.read_operand(1)

    defp process_and(data, cpu) do
      {cpu, _} = cpu |> and_with_acc(data) |> set_zero_flag() |> set_neg_flag()
      cpu
    end

    defp and_with_acc(cpu, data) do
      result = cpu |> Cpu.acc() |> band(data)
      cpu = cpu |> Cpu.acc(result)
      {cpu, result}
    end

    defp set_zero_flag({cpu, result}) do
      cpu = cpu |> Cpu.zero_flag(0 == result)
      {cpu, result}
    end

    defp set_neg_flag({cpu, result}) do
      nf = cpu |> Cpu.acc_size() |> check_neg_flag(result)
      cpu = cpu |> Cpu.negative_flag(nf)
      {cpu, result}
    end

    defp check_neg_flag(:bit16, result), do: 0x8000 == band(result, 0x8000)
    defp check_neg_flag(_, result), do: 0x80 == band(result, 0x80)

    defp load_data(:bit16, cpu, address), do: cpu |> Cpu.read_data(address, 2)
    defp load_data(_, cpu, address), do: cpu |> Cpu.read_data(address, 1)
  end
end
