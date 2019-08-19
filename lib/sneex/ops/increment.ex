defmodule Sneex.Ops.Increment do
  @moduledoc """
  This represents the op codes for incrementing a value (INC, INX, and INY).
  """
  defstruct [:opcode]

  use Bitwise

  @opaque t :: %__MODULE__{opcode: 0x1A | 0xEE | 0xE6 | 0xFE | 0xF6}

  @spec new(byte()) :: nil | Sneex.Ops.Increment.t()

  def new(0x1A), do: %__MODULE__{opcode: 0x1A}
  def new(0xEE), do: %__MODULE__{opcode: 0xEE}
  def new(0xE6), do: %__MODULE__{opcode: 0xE6}
  def new(0xFE), do: %__MODULE__{opcode: 0xFE}
  def new(0xF6), do: %__MODULE__{opcode: 0xF6}

  def new(_opcode), do: nil

  defimpl Sneex.Ops.Opcode do
    def byte_size(%{opcode: 0x1A}), do: 1
    def byte_size(%{opcode: 0xEE}), do: 3
    def byte_size(%{opcode: 0xE6}), do: 2
    def byte_size(%{opcode: 0xFE}), do: 3
    def byte_size(%{opcode: 0xF6}), do: 2

    def total_cycles(%{opcode: 0x1A}, _cpu), do: 2

    def total_cycles(%{opcode: 0xEE}, %{processor_status: status}) do
      status_cycles = add_16_bit_cycles(status)
      6 + status_cycles
    end

    def total_cycles(%{opcode: 0xE6}, %{processor_status: status, direct_page_register: dpr}) do
      status_cycles = add_16_bit_cycles(status)
      page_cycles = add_direct_page_cycles(dpr)
      5 + status_cycles + page_cycles
    end

    def total_cycles(%{opcode: 0xFE}, %{processor_status: status}) do
      7 + add_16_bit_cycles(status)
    end

    def total_cycles(%{opcode: 0xF6}, %{processor_status: status, direct_page_register: dpr}) do
      6 + add_16_bit_cycles(status) + add_direct_page_cycles(dpr)
    end

    defp add_16_bit_cycles(status) when (status &&& 0x20) == 0x20, do: 0
    defp add_16_bit_cycles(_status), do: 2

    defp add_direct_page_cycles(0x00), do: 0
    defp add_direct_page_cycles(_), do: 1

    def execute(%{opcode: 0x1A}, cpu = %{accumulator: a, processor_status: ps}, memory) do
      is_8_bit = is_8_bit_accumulator(ps)
      {new_a, status_set_mask} = increment(a, is_8_bit)

      new_status =
        ps
        |> band(0x7D)
        |> bor(status_set_mask)

      cpu = %{cpu | accumulator: new_a, processor_status: new_status}
      {cpu, memory}
    end

    def execute(
          %{opcode: 0xEE},
          cpu = %{
            data_bank_register: dbr,
            processor_status: ps,
            program_counter: pc,
            program_bank_register: pbr
          },
          memory
        ) do
      # Load the operand
      effective_pc = pbr |> bsl(16) |> bor(pc)
      address = read_data(memory, effective_pc + 1, false)

      # Read the data at the operand's address
      is_8_bit = is_8_bit_accumulator(ps)
      effective_address = dbr |> bsl(16) |> bor(address)
      data = read_data(memory, effective_address, is_8_bit)

      # Increment and write back
      {new_value, status_set_mask} = increment(data, is_8_bit)
      memory = write_data(memory, effective_address, new_value, is_8_bit)

      new_status =
        ps
        |> band(0x7D)
        |> bor(status_set_mask)

      cpu = %{cpu | processor_status: new_status}
      {cpu, memory}
    end

    def execute(
          %{opcode: 0xE6},
          cpu = %{
            direct_page_register: dpr,
            processor_status: ps,
            program_counter: pc,
            program_bank_register: pbr
          },
          memory
        ) do
      # Load the operand
      effective_pc = pbr |> bsl(16) |> bor(pc)

      address = read_data(memory, effective_pc + 1, true)

      # Read the data at the operand's address
      is_8_bit = is_8_bit_accumulator(ps)
      effective_address = (dpr + address) |> band(0x00FFFF)
      data = read_data(memory, effective_address, is_8_bit)

      # Increment and write back
      {new_value, status_set_mask} = increment(data, is_8_bit)
      memory = write_data(memory, effective_address, new_value, is_8_bit)

      new_status =
        ps
        |> band(0x7D)
        |> bor(status_set_mask)

      cpu = %{cpu | processor_status: new_status}
      {cpu, memory}
    end

    def execute(
          %{opcode: 0xFE},
          cpu = %{
            program_counter: pc,
            program_bank_register: pbr,
            processor_status: ps,
            data_bank_register: dbr,
            index_x: x
          },
          memory
        ) do
      # Load the operand
      effective_pc = pbr |> bsl(16) |> bor(pc)
      address = read_data(memory, effective_pc + 1, false)

      # Read the data at the operand's address
      is_8_bit = is_8_bit_accumulator(ps)
      effective_x = get_x_index(ps, x)
      effective_address = dbr |> bsl(16) |> bor(address)
      data = read_data(memory, effective_address + effective_x, is_8_bit)

      # Increment and write back
      {new_value, status_set_mask} = increment(data, is_8_bit)
      memory = write_data(memory, effective_address + effective_x, new_value, is_8_bit)

      new_status =
        ps
        |> band(0x7D)
        |> bor(status_set_mask)

      cpu = %{cpu | processor_status: new_status}
      {cpu, memory}
    end

    def execute(
          %{opcode: 0xF6},
          cpu = %{
            program_counter: pc,
            program_bank_register: pbr,
            processor_status: ps,
            direct_page_register: dpr,
            index_x: x
          },
          memory
        ) do
      # Load the operand
      effective_pc = pbr |> bsl(16) |> bor(pc)
      address = read_data(memory, effective_pc + 1, true)

      # Read the data at the operand's address
      is_8_bit = is_8_bit_accumulator(ps)
      effective_x = get_x_index(ps, x)
      effective_address = (dpr + effective_x + address) |> band(0x00FFFF)
      data = read_data(memory, effective_address, is_8_bit)

      # Increment and write back
      {new_value, status_set_mask} = increment(data, is_8_bit)
      memory = write_data(memory, effective_address, new_value, is_8_bit)

      new_status =
        ps
        |> band(0x7D)
        |> bor(status_set_mask)

      cpu = %{cpu | processor_status: new_status}
      {cpu, memory}
    end

    defp is_8_bit_accumulator(cpu_status) when (0x20 &&& cpu_status) == 0x20, do: true
    defp is_8_bit_accumulator(_cpu_status), do: false

    defp get_x_index(cpu_status, x) when (0x10 &&& cpu_status) == 0x10, do: x &&& 0x00FF
    defp get_x_index(_cpu_status, x), do: x &&& 0xFFFF

    defp read_data(memory, address, true), do: Sneex.Memory.read_byte(memory, address)
    defp read_data(memory, address, false), do: Sneex.Memory.read_word(memory, address)

    defp write_data(memory, address, data, true),
      do: Sneex.Memory.write_byte(memory, address, data)

    defp write_data(memory, address, data, false),
      do: Sneex.Memory.write_word(memory, address, data)

    # {curr_value, is_8_bit} => {new_vale, set_status_mask}

    defp increment(0xFF, _8_bit = true), do: {0, 0x02}
    defp increment(value, _8_bit = true) when value >= 0x7F, do: {value + 1, 0x80}
    defp increment(value, _8_bit = true) when value < 0x7F, do: {value + 1, 0x00}
    defp increment(0xFFFF, _8_bit = false), do: {0, 0x02}
    defp increment(value, _8_bit = false) when value >= 0x7FFF, do: {value + 1, 0x80}
    defp increment(value, _8_bit = false) when value < 0x7FFF, do: {value + 1, 0x00}

    def disasm(%{opcode: 0x1A}, _memory, _address), do: "INC A"

    def disasm(%{opcode: 0xEE}, memory, address) do
      addr = Sneex.Memory.read_word(memory, address + 1)
      "INC #{Sneex.BasicTypes.format_word(addr)}"
    end

    def disasm(%{opcode: 0xE6}, memory, address) do
      dp = Sneex.Memory.read_byte(memory, address + 1)
      "INC #{Sneex.BasicTypes.format_byte(dp)}"
    end

    def disasm(%{opcode: 0xFE}, memory, address) do
      addr = Sneex.Memory.read_word(memory, address + 1)
      "INC #{Sneex.BasicTypes.format_word(addr)},X"
    end

    def disasm(%{opcode: 0xF6}, memory, address) do
      dp = Sneex.Memory.read_byte(memory, address + 1)
      "INC #{Sneex.BasicTypes.format_byte(dp)},X"
    end
  end
end
