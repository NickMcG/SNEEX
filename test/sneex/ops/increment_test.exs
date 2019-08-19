defmodule Sneex.Ops.IncrementTest do
  use ExUnit.Case
  use Bitwise
  alias Sneex.Ops.{Increment, Opcode}
  alias Util.Test.DataBuilder

  test "new/1 returns nil for unknown opcodes" do
    assert nil == Increment.new(0x42)
  end

  describe "accumulator addressing mode" do
    setup do
      data = <<0x00, 0x00, 0x00, 0x00>>

      {:ok, memory: Sneex.Memory.new(data), opcode: Increment.new(0x1A)}
    end

    test "basic data", %{memory: memory, opcode: opcode} do
      assert 1 == Opcode.byte_size(opcode)
      assert 2 == Opcode.total_cycles(opcode, %{})
      assert "INC A" == Opcode.disasm(opcode, %{}, memory)
    end

    test "execute/3 with 16-bit mode", %{memory: memory, opcode: opcode} do
      # 0x0000 -> 0x0001
      cpu = %{processor_status: 0x00, accumulator: 0}
      {cpu, _} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status, accumulator: acc} = cpu

      assert 0x0001 == acc
      assert 0x00 == status

      # 0x0001 -> 0x0002
      {cpu, _} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status, accumulator: acc} = cpu

      assert 0x0002 == acc
      assert 0x00 == status

      # 0x7FFF -> 0x8000
      cpu = %{cpu | accumulator: 0x7FFF}
      {cpu, _} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status, accumulator: acc} = cpu

      assert 0x8000 == acc
      assert 0x80 == status

      # 0xFFFF -> 0x00
      cpu = %{cpu | accumulator: 0xFFFF}
      {cpu, _} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status, accumulator: acc} = cpu

      assert 0x00 == acc
      assert 0x02 == status
    end

    test "execute/3 with 8-bit mode", %{memory: memory} do
      opcode = Increment.new(0x1A)

      # 0x00 -> 0x01
      cpu = %{processor_status: 0x20, direct_page_register: 0x00, accumulator: 0}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status, accumulator: acc} = cpu

      assert 0x01 == acc
      assert 0x20 == status

      # 0x01 -> 0x02
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status, accumulator: acc} = cpu

      assert 0x02 == acc
      assert 0x20 == status

      # 0x7F -> 0x80
      cpu = %{cpu | accumulator: 0x7F}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status, accumulator: acc} = cpu

      assert 0x80 == acc
      assert 0xA0 == status

      # 0xFF -> 0x00
      cpu = %{cpu | accumulator: 0xFF}
      {cpu, _memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status, accumulator: acc} = cpu

      assert 0x00 == acc
      assert 0x22 == status
    end
  end

  describe "absolute addressing mode, 8-bit" do
    setup do
      data_to_inc = <<0x00, 0x01, 0x7F, 0xFF>>
      commands = <<0xEE, 0x00, 0x00, 0xEE, 0x01, 0x00, 0xEE, 0x02, 0x00, 0xEE, 0x03, 0x00>>
      rest_of_page = DataBuilder.build_block_of_00s(Util.Bank.bank_size() - 16)
      page = data_to_inc <> commands <> rest_of_page
      data = page <> page

      cpu = %{
        processor_status: 0x20,
        data_bank_register: 0x00,
        program_counter: 0x0000,
        program_bank_register: 0x00
      }

      memory = Sneex.Memory.new(data)
      opcode = Increment.new(0xEE)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      # direct page == 0
      assert 3 == Opcode.byte_size(opcode)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "INC $0000" == Opcode.disasm(opcode, memory, 0x0004)

      # direct page != 0
      cpu = %{cpu | data_bank_register: 0x01}
      assert 3 == Opcode.byte_size(opcode)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "INC $0003" == Opcode.disasm(opcode, memory, 0x000D)
    end

    test "execute/3", %{cpu: cpu, memory: memory, opcode: opcode} do
      # 0x00 -> 0x01
      cpu = %{cpu | program_counter: 0x0004}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x20 == status

      # 0x01 -> 0x02
      cpu = %{cpu | program_counter: 0x0007}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x20 == status

      # 0x7F -> 0x80
      cpu = %{cpu | program_counter: 0x000A}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0xA0 == status

      # 0xFF -> 0x00
      cpu = %{cpu | program_counter: 0x000D}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x22 == status

      expected = <<0x01, 0x02, 0x80, 0x00>>

      <<actual::binary-size(4), _rest::binary>> = Sneex.Memory.raw_data(memory)

      assert expected == actual
    end
  end

  describe "absolute addressing mode, 16-bit" do
    setup do
      data_to_inc = <<0x00, 0x00, 0x01, 0x00, 0xFF, 0x7F, 0xFF, 0xFF>>
      commands = <<0xEE, 0x00, 0x00, 0xEE, 0x02, 0x00, 0xEE, 0x04, 0x00, 0xEE, 0x06, 0x00>>
      rest_of_page = DataBuilder.build_block_of_00s(Util.Bank.bank_size() - 20)
      page = data_to_inc <> commands <> rest_of_page
      data = page <> page

      cpu = %{
        processor_status: 0x00,
        data_bank_register: 0x00,
        program_counter: 0x0000,
        program_bank_register: 0x00
      }

      memory = Sneex.Memory.new(data)
      opcode = Increment.new(0xEE)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      # direct page == 0
      assert 3 == Opcode.byte_size(opcode)
      assert 8 == Opcode.total_cycles(opcode, cpu)
      assert "INC $0002" == Opcode.disasm(opcode, memory, 0x000B)

      # direct page != 0
      cpu = %{cpu | data_bank_register: 0x01}
      assert 3 == Opcode.byte_size(opcode)
      assert 8 == Opcode.total_cycles(opcode, cpu)
      assert "INC $0004" == Opcode.disasm(opcode, memory, 0x000E)
    end

    test "execute/3", %{cpu: cpu, memory: memory, opcode: opcode} do
      # 0x0000 -> 0x0001
      cpu = %{cpu | program_counter: 0x0008}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x00 == status

      # 0x0001 -> 0x0002
      cpu = %{cpu | program_counter: 0x000B}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x00 == status

      # 0x7FFF -> 0x8000
      cpu = %{cpu | program_counter: 0x000E}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x80 == status

      # 0xFFFF -> 0x0000
      cpu = %{cpu | program_counter: 0x0011}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x02 == status

      expected = <<0x01, 0x00, 0x02, 0x00, 0x00, 0x80, 0x00, 0x00>>

      <<actual::binary-size(8), _rest::binary>> = Sneex.Memory.raw_data(memory)

      assert expected == actual
    end
  end

  describe "direct page addressing mode, 8-bit" do
    setup do
      data_to_inc = <<0x00, 0x01, 0x7F, 0xFF>>
      commands = <<0xEE, 0x00, 0xEE, 0x01, 0xEE, 0x02, 0xEE, 0x03>>

      cpu = %{
        processor_status: 0x20,
        program_counter: 0x0000,
        program_bank_register: 0x00,
        direct_page_register: 0x0000
      }

      memory = Sneex.Memory.new(data_to_inc <> commands)
      opcode = Increment.new(0xE6)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 5 == Opcode.total_cycles(opcode, cpu)
      assert "INC $00" == Opcode.disasm(opcode, memory, 0x0004)

      cpu = %{cpu | direct_page_register: 0x01}
      assert 2 == Opcode.byte_size(opcode)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "INC $03" == Opcode.disasm(opcode, memory, 0x000A)
    end

    test "execute/3", %{cpu: cpu, memory: memory, opcode: opcode} do
      # 0x00 -> 0x01
      cpu = %{cpu | program_counter: 0x0004}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x20 == status

      # 0x01 -> 0x02
      cpu = %{cpu | program_counter: 0x0006}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x20 == status

      # 0x7F -> 0x80
      cpu = %{cpu | program_counter: 0x0008}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0xA0 == status

      # 0xFF -> 0x00
      cpu = %{cpu | program_counter: 0x000A}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x22 == status

      expected = <<0x01, 0x02, 0x80, 0x00>>

      <<actual::binary-size(4), _rest::binary>> = Sneex.Memory.raw_data(memory)

      assert expected == actual
    end
  end

  describe "direct page addressing mode, 16-bit" do
    setup do
      data_to_inc = <<0x00, 0x00, 0x01, 0x00, 0xFF, 0x7F, 0xFF, 0xFF>>
      commands = <<0xE6, 0x00, 0xE6, 0x02, 0xE6, 0x04, 0xE6, 0x06>>

      cpu = %{
        processor_status: 0x00,
        program_counter: 0x0000,
        program_bank_register: 0x00,
        direct_page_register: 0x0000
      }

      memory = Sneex.Memory.new(data_to_inc <> commands)
      opcode = Increment.new(0xE6)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "INC $00" == Opcode.disasm(opcode, memory, 0x0008)

      assert 2 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "INC $06" == Opcode.disasm(opcode, memory, 0x000E)
    end

    test "execute/3", %{cpu: cpu, memory: memory, opcode: opcode} do
      # 0x00 -> 0x01
      cpu = %{cpu | program_counter: 0x0008}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x00 == status

      # 0x01 -> 0x02
      cpu = %{cpu | program_counter: 0x000A}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x00 == status

      # 0x7F -> 0x80
      cpu = %{cpu | program_counter: 0x000C}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x80 == status

      # 0xFF -> 0x00
      cpu = %{cpu | program_counter: 0x000E}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x02 == status

      expected = <<0x01, 0x00, 0x02, 0x00, 0x00, 0x80, 0x00, 0x00>>

      <<actual::binary-size(8), _rest::binary>> = Sneex.Memory.raw_data(memory)

      assert expected == actual
    end
  end

  describe "absolute x-indexed addressing mode, 8-bit" do
    setup do
      buffer = <<0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      data_to_inc = <<0x00, 0x01, 0x7F, 0xFF>>
      commands = <<0xFE, 0x00, 0x00, 0xFE, 0x01, 0x00, 0xFE, 0x02, 0x00, 0xFE, 0x03, 0x00>>

      cpu = %{
        processor_status: 0x20,
        program_counter: 0x0000,
        program_bank_register: 0x00,
        data_bank_register: 0x0000,
        index_x: 0x0010
      }

      memory = Sneex.Memory.new(buffer <> buffer <> data_to_inc <> commands)
      opcode = Increment.new(0xFE)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 3 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "INC $0000,X" == Opcode.disasm(opcode, memory, 0x0014)

      assert 3 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "INC $0002,X" == Opcode.disasm(opcode, memory, 0x001A)
    end

    test "execute/3", %{cpu: cpu, memory: memory, opcode: opcode} do
      # 0x00 -> 0x01
      cpu = %{cpu | program_counter: 0x0014}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x20 == status

      # 0x01 -> 0x02
      cpu = %{cpu | program_counter: 0x0017}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x20 == status

      # 0x7F -> 0x80
      cpu = %{cpu | program_counter: 0x001A}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0xA0 == status

      # 0xFF -> 0x00
      cpu = %{cpu | program_counter: 0x001D}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x22 == status

      expected = <<0x01, 0x02, 0x80, 0x00>>

      <<_before::binary-size(16), actual::binary-size(4), _rest::binary>> =
        Sneex.Memory.raw_data(memory)

      assert expected == actual
    end
  end

  describe "absolute x-indexed addressing mode, 16-bit" do
    setup do
      buffer = <<0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      data_to_inc = <<0x00, 0x00, 0x01, 0x00, 0xFF, 0x7F, 0xFF, 0xFF>>
      commands = <<0xFE, 0x00, 0x00, 0xFE, 0x02, 0x00, 0xFE, 0x04, 0x00, 0xFE, 0x06, 0x00>>

      cpu = %{
        processor_status: 0x10,
        program_counter: 0x0000,
        program_bank_register: 0x00,
        data_bank_register: 0x0000,
        index_x: 0x0010
      }

      memory = Sneex.Memory.new(buffer <> buffer <> data_to_inc <> commands)
      opcode = Increment.new(0xFE)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 3 == Opcode.byte_size(opcode)
      assert 9 == Opcode.total_cycles(opcode, cpu)
      assert "INC $0000,X" == Opcode.disasm(opcode, memory, 0x0018)

      assert 3 == Opcode.byte_size(opcode)
      assert 9 == Opcode.total_cycles(opcode, cpu)
      assert "INC $0006,X" == Opcode.disasm(opcode, memory, 0x0021)
    end

    test "execute/3", %{cpu: cpu, memory: memory, opcode: opcode} do
      # 0x0000 -> 0x0001
      cpu = %{cpu | program_counter: 0x0018}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x10 == status

      # 0x0001 -> 0x0002
      cpu = %{cpu | program_counter: 0x001B}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x10 == status

      # 0x7FFF -> 0x8000
      cpu = %{cpu | program_counter: 0x001E}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x90 == status

      # 0xFFFF -> 0x0000
      cpu = %{cpu | program_counter: 0x0021}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x12 == status

      expected = <<0x01, 0x00, 0x02, 0x00, 0x00, 0x80, 0x00, 0x00>>

      <<_before::binary-size(16), actual::binary-size(8), _rest::binary>> =
        Sneex.Memory.raw_data(memory)

      assert expected == actual
    end
  end

  describe "direct page x-indexed addressing mode, 8-bit" do
    setup do
      buffer = <<0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      data_to_inc = <<0x00, 0x01, 0x7F, 0xFF>>
      commands = <<0xFE, 0x00, 0x00, 0xFE, 0x01, 0x00, 0xFE, 0x02, 0x00, 0xFE, 0x03, 0x00>>

      cpu = %{
        processor_status: 0x30,
        program_counter: 0x0000,
        program_bank_register: 0x00,
        direct_page_register: 0x0000,
        index_x: 0x0010
      }

      memory = Sneex.Memory.new(buffer <> buffer <> data_to_inc <> commands)
      opcode = Increment.new(0xF6)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 6 == Opcode.total_cycles(opcode, cpu)
      assert "INC $00,X" == Opcode.disasm(opcode, memory, 0x0014)

      cpu = %{cpu | direct_page_register: 0x01}
      assert 2 == Opcode.byte_size(opcode)
      assert 7 == Opcode.total_cycles(opcode, cpu)
      assert "INC $02,X" == Opcode.disasm(opcode, memory, 0x001A)
    end

    test "execute/3", %{cpu: cpu, memory: memory, opcode: opcode} do
      # 0x00 -> 0x01
      cpu = %{cpu | program_counter: 0x0014}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x30 == status

      # 0x01 -> 0x02
      cpu = %{cpu | program_counter: 0x0017}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x30 == status

      # 0x7F -> 0x80
      cpu = %{cpu | program_counter: 0x001A}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0xB0 == status

      # 0xFF -> 0x00
      cpu = %{cpu | program_counter: 0x001D}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x32 == status

      expected = <<0x01, 0x02, 0x80, 0x00>>

      <<_before::binary-size(16), actual::binary-size(4), _rest::binary>> =
        Sneex.Memory.raw_data(memory)

      assert expected == actual
    end
  end

  describe "direct page x-indexed addressing mode, 16-bit" do
    setup do
      buffer = <<0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      data_to_inc = <<0x00, 0x00, 0x01, 0x00, 0xFF, 0x7F, 0xFF, 0xFF>>
      commands = <<0xF6, 0x00, 0xF6, 0x02, 0xF6, 0x04, 0xF6, 0x06>>

      cpu = %{
        processor_status: 0x10,
        program_counter: 0x0000,
        program_bank_register: 0x00,
        direct_page_register: 0x0000,
        index_x: 0x0010
      }

      memory = Sneex.Memory.new(buffer <> buffer <> data_to_inc <> commands)
      opcode = Increment.new(0xF6)

      {:ok, cpu: cpu, memory: memory, opcode: opcode}
    end

    test "basic data", %{cpu: cpu, memory: memory, opcode: opcode} do
      assert 2 == Opcode.byte_size(opcode)
      assert 8 == Opcode.total_cycles(opcode, cpu)
      assert "INC $00,X" == Opcode.disasm(opcode, memory, 0x0018)

      cpu = %{cpu | direct_page_register: 0x01}
      assert 2 == Opcode.byte_size(opcode)
      assert 9 == Opcode.total_cycles(opcode, cpu)
      assert "INC $06,X" == Opcode.disasm(opcode, memory, 0x001E)
    end

    test "execute/3", %{cpu: cpu, memory: memory, opcode: opcode} do
      # 0x0000 -> 0x0001
      cpu = %{cpu | program_counter: 0x0018}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x10 == status

      # 0x0001 -> 0x0002
      cpu = %{cpu | program_counter: 0x001A}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x10 == status

      # 0x7FFF -> 0x8000
      cpu = %{cpu | program_counter: 0x001C}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x90 == status

      # 0xFFFF -> 0x0000
      cpu = %{cpu | program_counter: 0x001E}
      {cpu, memory} = Opcode.execute(opcode, cpu, memory)
      %{processor_status: status} = cpu

      assert 0x12 == status

      expected = <<0x01, 0x00, 0x02, 0x00, 0x00, 0x80, 0x00, 0x00>>

      <<_before::binary-size(16), actual::binary-size(8), _rest::binary>> =
        Sneex.Memory.raw_data(memory)

      assert expected == actual
    end
  end
end
