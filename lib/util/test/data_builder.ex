defmodule Util.Test.DataBuilder do
  @moduledoc """
  This is a module that makes it easier to generate data for tests.

  This is not really intended for main consumption
  """
  def build_block_of_ffs(length) do
    append_ffs_to_block(<<>>, length)
  end

  defp append_ffs_to_block(data, 0) do
    data
  end

  defp append_ffs_to_block(data, count) when count >= 16 do
    ffs =
      <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF>>

    append_ffs_to_block(data <> ffs, count - 16)
  end

  defp append_ffs_to_block(data, count) do
    append_ffs_to_block(data <> <<0xFF>>, count - 1)
  end

  def build_final_fantasy_2_header do
    <<
      0x46,
      0x49,
      0x4E,
      0x41,
      0x4C,
      0x20,
      0x46,
      0x41,
      0x4E,
      0x54,
      0x41,
      0x53,
      0x59,
      0x20,
      0x49,
      0x49,
      0x20,
      0x20,
      0x20,
      0x20,
      0x20,
      0x20,
      0x02,
      0x0A,
      0x03,
      0x01,
      0xC3,
      0x00,
      0x0F,
      0x7A,
      0xF0,
      0x85,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x00,
      0x02,
      0xFF,
      0xFF,
      0x04,
      0x02,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0x00,
      0x80,
      0xFF,
      0xFF
    >>
  end
end
