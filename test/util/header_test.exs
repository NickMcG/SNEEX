defmodule Util.HeaderTest do
  use ExUnit.Case
  import Util.Test.DataBuilder

  test "new returns invalid if passed an invalid header block" do
    data = build_block_of_ffs(64)
    assert Util.Header.new(data) == :invalid
  end

  test "new returns a header if passed a valid header block" do
    data = build_final_fantasy_2_header()

    header = Util.Header.new(data)
    assert header.title == "FINAL FANTASY II"
    assert header.rom_makeup == :lorom
    assert header.rom_type == :rom
    assert header.rom_size == 1_048_576
    assert header.sram_size == 8_192
    assert header.license_id == 0x01
    assert header.version_number == 0xC3
    assert header.checksum == 0x7AF0
    assert header.checksum_complement == 0x000F

    # Check the native mode vectors
    assert header.native_mode_interrupts.coprocessor == 0xFFFF
    assert header.native_mode_interrupts.break == 0xFFFF
    assert header.native_mode_interrupts.non_maskable == 0x0200
    assert header.native_mode_interrupts.abort == 0xFFFF
    assert header.native_mode_interrupts.reset == 0xFFFF
    assert header.native_mode_interrupts.irq == 0x0204

    # Check the emulation mode vectors
    assert header.emulation_mode_interrupts.coprocessor == 0xFFFF
    assert header.emulation_mode_interrupts.break == 0xFFFF
    assert header.emulation_mode_interrupts.non_maskable == 0xFFFF
    assert header.emulation_mode_interrupts.abort == 0xFFFF
    assert header.emulation_mode_interrupts.reset == 0x8000
    assert header.emulation_mode_interrupts.irq == 0xFFFF
  end
end
