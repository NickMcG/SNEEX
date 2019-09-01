defmodule Sneex.AddressModeTest do
  use ExUnit.Case
  alias Sneex.{AddressMode, Cpu, Memory}
  alias Util.Test.DataBuilder
  doctest Sneex.AddressMode

  setup do
    cpu = <<>> |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)
    {:ok, cpu: cpu}
  end

  test "absolute/3", %{cpu: cpu} do
    cpu = cpu |> Cpu.data_bank(0x00) |> Cpu.program_bank(0xFF)
    assert 0x000000 == AddressMode.absolute(cpu, true, 0x0000)
    assert 0x00DEAD == AddressMode.absolute(cpu, true, 0xDEAD)
    assert 0x00BEEF == AddressMode.absolute(cpu, true, 0xBEEF)
    assert 0x00FFFF == AddressMode.absolute(cpu, true, 0xFFFF)

    assert 0xFF0000 == AddressMode.absolute(cpu, false, 0x0000)
    assert 0xFFDEAD == AddressMode.absolute(cpu, false, 0xDEAD)
    assert 0xFFBEEF == AddressMode.absolute(cpu, false, 0xBEEF)
    assert 0xFFFFFF == AddressMode.absolute(cpu, false, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0x01) |> Cpu.program_bank(0x01)
    assert 0x010000 == AddressMode.absolute(cpu, true, 0x0000)
    assert 0x01DEAD == AddressMode.absolute(cpu, true, 0xDEAD)
    assert 0x01BEEF == AddressMode.absolute(cpu, true, 0xBEEF)
    assert 0x01FFFF == AddressMode.absolute(cpu, true, 0xFFFF)

    assert 0x010000 == AddressMode.absolute(cpu, false, 0x0000)
    assert 0x01DEAD == AddressMode.absolute(cpu, false, 0xDEAD)
    assert 0x01BEEF == AddressMode.absolute(cpu, false, 0xBEEF)
    assert 0x01FFFF == AddressMode.absolute(cpu, false, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0xFF) |> Cpu.program_bank(0x00)
    assert 0xFF0000 == AddressMode.absolute(cpu, true, 0x0000)
    assert 0xFFDEAD == AddressMode.absolute(cpu, true, 0xDEAD)
    assert 0xFFBEEF == AddressMode.absolute(cpu, true, 0xBEEF)
    assert 0xFFFFFF == AddressMode.absolute(cpu, true, 0xFFFF)

    assert 0x000000 == AddressMode.absolute(cpu, false, 0x0000)
    assert 0x00DEAD == AddressMode.absolute(cpu, false, 0xDEAD)
    assert 0x00BEEF == AddressMode.absolute(cpu, false, 0xBEEF)
    assert 0x00FFFF == AddressMode.absolute(cpu, false, 0xFFFF)
  end

  test "absolute_indexed_x/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.data_bank(0x00) |> Cpu.x(0x0000) |> Cpu.index_size(:bit16)

    assert 0x000000 == AddressMode.absolute_indexed_x(cpu, 0x0000)
    assert 0x00DEAD == AddressMode.absolute_indexed_x(cpu, 0xDEAD)
    assert 0x00BEEF == AddressMode.absolute_indexed_x(cpu, 0xBEEF)
    assert 0x00FFFF == AddressMode.absolute_indexed_x(cpu, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0x01) |> Cpu.x(0x0142) |> Cpu.program_bank(0x01)
    assert 0x010142 == AddressMode.absolute_indexed_x(cpu, 0x0000)
    assert 0x01DFEF == AddressMode.absolute_indexed_x(cpu, 0xDEAD)
    assert 0x01C031 == AddressMode.absolute_indexed_x(cpu, 0xBEEF)
    assert 0x020141 == AddressMode.absolute_indexed_x(cpu, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0xFF) |> Cpu.index_size(:bit8)
    assert 0xFF0042 == AddressMode.absolute_indexed_x(cpu, 0x0000)
    assert 0xFFDEEF == AddressMode.absolute_indexed_x(cpu, 0xDEAD)
    assert 0xFFBF31 == AddressMode.absolute_indexed_x(cpu, 0xBEEF)
    assert 0x000041 == AddressMode.absolute_indexed_x(cpu, 0xFFFF)
  end

  test "absolute_indexed_y/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.data_bank(0x00) |> Cpu.y(0x0000) |> Cpu.index_size(:bit16)

    assert 0x000000 == AddressMode.absolute_indexed_y(cpu, 0x0000)
    assert 0x00DEAD == AddressMode.absolute_indexed_y(cpu, 0xDEAD)
    assert 0x00BEEF == AddressMode.absolute_indexed_y(cpu, 0xBEEF)
    assert 0x00FFFF == AddressMode.absolute_indexed_y(cpu, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0x01) |> Cpu.y(0x0142) |> Cpu.program_bank(0x01)
    assert 0x010142 == AddressMode.absolute_indexed_y(cpu, 0x0000)
    assert 0x01DFEF == AddressMode.absolute_indexed_y(cpu, 0xDEAD)
    assert 0x01C031 == AddressMode.absolute_indexed_y(cpu, 0xBEEF)
    assert 0x020141 == AddressMode.absolute_indexed_y(cpu, 0xFFFF)

    cpu = cpu |> Cpu.data_bank(0xFF) |> Cpu.index_size(:bit8)
    assert 0xFF0042 == AddressMode.absolute_indexed_y(cpu, 0x0000)
    assert 0xFFDEEF == AddressMode.absolute_indexed_y(cpu, 0xDEAD)
    assert 0xFFBF31 == AddressMode.absolute_indexed_y(cpu, 0xBEEF)
    assert 0x000041 == AddressMode.absolute_indexed_y(cpu, 0xFFFF)
  end

  test "absolute_indexed_indirect/1" do
    blank_bank = DataBuilder.build_block_of_00s(0x10000)
    data = blank_bank <> <<0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0xAA, 0xFF>>
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x01) |> Cpu.pc(0x01) |> Cpu.x(0x03)
    assert 0x01FFAA == AddressMode.absolute_indexed_indirect(cpu)
  end

  test "absolute_indirect/1" do
    bank00 =
      DataBuilder.build_block_of_00s(0xBEEF) <>
        <<0x2A, 0xA4>> <> DataBuilder.build_block_of_00s(0x410F)

    bank01 = <<0x00, 0x00, 0x00, 0x00, 0xEF, 0xBE>>
    data = bank00 <> bank01
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x01) |> Cpu.pc(0x03)
    assert 0x01A42A == AddressMode.absolute_indirect(cpu)
  end

  test "absolute_indirect_long/1" do
    bank00 =
      DataBuilder.build_block_of_00s(0xBEEF) <>
        <<0x2A, 0xA4, 0x42>> <> DataBuilder.build_block_of_00s(0x410E)

    bank01 = <<0x00, 0x00, 0x00, 0x00, 0xEF, 0xBE>>
    data = bank00 <> bank01
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x01) |> Cpu.pc(0x03)
    assert 0x42A42A == AddressMode.absolute_indirect_long(cpu)
  end

  test "absolute_long/1" do
    data = <<0x00, 0x00, 0xEF, 0xBE>>
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x00) |> Cpu.pc(0x00)
    assert 0xBEEF00 == AddressMode.absolute_long(cpu)
  end

  test "absolute_long_indexed_x/1" do
    data = <<0x00, 0x00, 0xEF, 0xBE>>
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x00) |> Cpu.pc(0x00) |> Cpu.x(0xDEAD)
    assert 0xBEEFAD == AddressMode.absolute_long_indexed_x(cpu)

    cpu = cpu |> Cpu.index_size(:bit16)
    assert 0xBFCDAD == AddressMode.absolute_long_indexed_x(cpu)
  end

  test "block_move/1" do
    data = <<0x00, 0xEF, 0xBE>>
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native) |> Cpu.acc(0x1881)

    cpu = cpu |> Cpu.program_bank(0x00) |> Cpu.pc(0x00) |> Cpu.x(0xDEAD) |> Cpu.y(0xBEEF)
    assert {0xBE00AD, 0xEF00EF, 0x1882} == AddressMode.block_move(cpu)

    cpu = cpu |> Cpu.index_size(:bit16) |> Cpu.acc_size(:bit16)
    assert {0xBEDEAD, 0xEFBEEF, 0x1882} == AddressMode.block_move(cpu)
  end

  test "direct_page/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.direct_page(0x0000)
    assert 0x000000 == AddressMode.direct_page(cpu, 0x0000)
    assert 0x00DEAD == AddressMode.direct_page(cpu, 0xDEAD)
    assert 0x00BEEF == AddressMode.direct_page(cpu, 0xBEEF)
    assert 0x00FFFF == AddressMode.direct_page(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x1111)
    assert 0x001111 == AddressMode.direct_page(cpu, 0x0000)
    assert 0x00EFBE == AddressMode.direct_page(cpu, 0xDEAD)
    assert 0x00D000 == AddressMode.direct_page(cpu, 0xBEEF)
    assert 0x001110 == AddressMode.direct_page(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x4242)
    assert 0x004242 == AddressMode.direct_page(cpu, 0x0000)
    assert 0x0020EF == AddressMode.direct_page(cpu, 0xDEAD)
    assert 0x000131 == AddressMode.direct_page(cpu, 0xBEEF)
    assert 0x004241 == AddressMode.direct_page(cpu, 0xFFFF)
  end

  test "direct_page_indexed_x/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.direct_page(0x0000) |> Cpu.x(0x0000) |> Cpu.index_size(:bit16)
    assert 0x000000 == AddressMode.direct_page_indexed_x(cpu, 0x0000)
    assert 0x00DEAD == AddressMode.direct_page_indexed_x(cpu, 0xDEAD)
    assert 0x00BEEF == AddressMode.direct_page_indexed_x(cpu, 0xBEEF)
    assert 0x00FFFF == AddressMode.direct_page_indexed_x(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x1111) |> Cpu.x(0x0142)
    assert 0x001253 == AddressMode.direct_page_indexed_x(cpu, 0x0000)
    assert 0x00F100 == AddressMode.direct_page_indexed_x(cpu, 0xDEAD)
    assert 0x00D142 == AddressMode.direct_page_indexed_x(cpu, 0xBEEF)
    assert 0x001252 == AddressMode.direct_page_indexed_x(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x4242) |> Cpu.index_size(:bit8)
    assert 0x004284 == AddressMode.direct_page_indexed_x(cpu, 0x0000)
    assert 0x002131 == AddressMode.direct_page_indexed_x(cpu, 0xDEAD)
    assert 0x000173 == AddressMode.direct_page_indexed_x(cpu, 0xBEEF)
    assert 0x004283 == AddressMode.direct_page_indexed_x(cpu, 0xFFFF)
  end

  test "direct_page_indexed_y/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.direct_page(0x0000) |> Cpu.y(0x0000) |> Cpu.index_size(:bit16)
    assert 0x000000 == AddressMode.direct_page_indexed_y(cpu, 0x0000)
    assert 0x00DEAD == AddressMode.direct_page_indexed_y(cpu, 0xDEAD)
    assert 0x00BEEF == AddressMode.direct_page_indexed_y(cpu, 0xBEEF)
    assert 0x00FFFF == AddressMode.direct_page_indexed_y(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x1111) |> Cpu.y(0x0142)
    assert 0x001253 == AddressMode.direct_page_indexed_y(cpu, 0x0000)
    assert 0x00F100 == AddressMode.direct_page_indexed_y(cpu, 0xDEAD)
    assert 0x00D142 == AddressMode.direct_page_indexed_y(cpu, 0xBEEF)
    assert 0x001252 == AddressMode.direct_page_indexed_y(cpu, 0xFFFF)

    cpu = cpu |> Cpu.direct_page(0x4242) |> Cpu.index_size(:bit8)
    assert 0x004284 == AddressMode.direct_page_indexed_y(cpu, 0x0000)
    assert 0x002131 == AddressMode.direct_page_indexed_y(cpu, 0xDEAD)
    assert 0x000173 == AddressMode.direct_page_indexed_y(cpu, 0xBEEF)
    assert 0x004283 == AddressMode.direct_page_indexed_y(cpu, 0xFFFF)
  end

  test "direct_page_indexed_indirect/1" do
    bank00 =
      DataBuilder.build_block_of_00s(0xBEEF) <>
        <<0x2A, 0xA4>> <> DataBuilder.build_block_of_00s(0x410F)

    bank01 = <<0x00, 0x00, 0x22>>
    data = bank00 <> bank01
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native) |> Cpu.index_size(:bit16)

    cpu = cpu |> Cpu.program_bank(0x01) |> Cpu.pc(0x01) |> Cpu.x(0x103) |> Cpu.direct_page(0xBDCA)
    cpu = cpu |> Cpu.data_bank(0x42)
    assert 0x42A42A == AddressMode.direct_page_indexed_indirect(cpu)
  end

  test "direct_page_indirect/1" do
    bank00 =
      DataBuilder.build_block_of_00s(0xBEEF) <>
        <<0x2A, 0xA4>> <> DataBuilder.build_block_of_00s(0x410F)

    bank01 = <<0x00, 0x00, 0xAA>>
    data = bank00 <> bank01
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x01) |> Cpu.pc(0x01) |> Cpu.direct_page(0xBE45)
    cpu = cpu |> Cpu.data_bank(0x24)
    assert 0x24A42A == AddressMode.direct_page_indirect(cpu)
  end

  test "direct_page_indirect_long/1" do
    bank00 =
      DataBuilder.build_block_of_00s(0xBEEF) <>
        <<0x2A, 0xA4, 0x11>> <> DataBuilder.build_block_of_00s(0x410E)

    bank01 = <<0x00, 0x00, 0xAA>>
    data = bank00 <> bank01
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x01) |> Cpu.pc(0x01) |> Cpu.direct_page(0xBE45)
    assert 0x11A42A == AddressMode.direct_page_indirect_long(cpu)
  end

  test "direct_page_indirect_indexed_y/1" do
    bank00 =
      DataBuilder.build_block_of_00s(0xBEEF) <>
        <<0x2A, 0xA4>> <> DataBuilder.build_block_of_00s(0x410F)

    bank01 = <<0x00, 0x00, 0xAA>>
    data = bank00 <> bank01
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native) |> Cpu.index_size(:bit16)

    cpu = cpu |> Cpu.program_bank(0x01) |> Cpu.pc(0x01) |> Cpu.direct_page(0xBE45)
    cpu = cpu |> Cpu.y(0x1111) |> Cpu.data_bank(0x22)
    assert 0x22B53B == AddressMode.direct_page_indirect_indexed_y(cpu)
  end

  test "direct_page_indirect_long_indexed_y/1" do
    bank00 =
      DataBuilder.build_block_of_00s(0xBEEF) <>
        <<0x2A, 0xA4, 0x33>> <> DataBuilder.build_block_of_00s(0x410E)

    bank01 = <<0x00, 0x00, 0xAA>>
    data = bank00 <> bank01
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native) |> Cpu.index_size(:bit16)

    cpu =
      cpu |> Cpu.program_bank(0x01) |> Cpu.pc(0x01) |> Cpu.direct_page(0xBE45) |> Cpu.y(0x1111)

    assert 0x33B53B == AddressMode.direct_page_indirect_long_indexed_y(cpu)
  end

  test "program_counter_relative/1" do
    data = <<0x00, 0x00, 0xFE, 0x00, 0x73>>
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x00) |> Cpu.pc(0x0000)
    assert 0x000002 == AddressMode.program_counter_relative(cpu)

    cpu = cpu |> Cpu.program_bank(0x00) |> Cpu.pc(0x0001)
    assert 0x000001 == AddressMode.program_counter_relative(cpu)

    cpu = cpu |> Cpu.pc(0x0003)
    assert 0x000078 == AddressMode.program_counter_relative(cpu)
  end

  test "program_counter_relative_long/1" do
    data = <<0x00, 0xFE, 0xFF, 0x00, 0x73>>
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x00) |> Cpu.pc(0x0000)
    assert 0x000001 == AddressMode.program_counter_relative_long(cpu)

    cpu = cpu |> Cpu.program_bank(0x00) |> Cpu.pc(0x0001)
    assert 0x000103 == AddressMode.program_counter_relative_long(cpu)

    cpu = cpu |> Cpu.pc(0x0002)
    assert 0x007305 == AddressMode.program_counter_relative_long(cpu)
  end

  test "stack_relative/1" do
    data = <<0x00, 0xFE, 0xFF, 0x00, 0x73>>
    cpu = data |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)

    cpu = cpu |> Cpu.program_bank(0x00) |> Cpu.pc(0x0000) |> Cpu.stack_ptr(0x1234)
    assert 0x001332 == AddressMode.stack_relative(cpu)

    cpu = cpu |> Cpu.program_bank(0x00) |> Cpu.pc(0x0001) |> Cpu.stack_ptr(0x4321)
    assert 0x004420 == AddressMode.stack_relative(cpu)

    cpu = cpu |> Cpu.pc(0x0003) |> Cpu.stack_ptr(0xDEAD)
    assert 0x00DF20 == AddressMode.stack_relative(cpu)
  end

  test "stack_relative_indirect_indexed_y" do
    data =
      DataBuilder.build_block_of_00s(0xA) <>
        <<0x00, 0xFE, 0xFF, 0x00, 0x73>> <>
        DataBuilder.build_block_of_00s(0xFFF0) <> <<0x00, 0x00, 0x01, 0x02, 0x03>>

    cpu =
      data
      |> Memory.new()
      |> Cpu.new()
      |> Cpu.stack_ptr(0x000A)
      |> Cpu.program_bank(0x01)
      |> Cpu.y(0x42)
      |> Cpu.data_bank(0xAA)

    cpu = cpu |> Cpu.pc(0x0000)
    assert 0xAB0040 == AddressMode.stack_relative_indirect_indexed_y(cpu)

    cpu = cpu |> Cpu.pc(0x0001)
    assert 0xAA0141 == AddressMode.stack_relative_indirect_indexed_y(cpu)

    cpu = cpu |> Cpu.pc(0x0002)
    assert 0xAA7342 == AddressMode.stack_relative_indirect_indexed_y(cpu)
  end
end
