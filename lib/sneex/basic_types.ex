defmodule Sneex.BasicTypes do
  @moduledoc """
  This module defines some basic data types that are used across the application.
  """

  @type word :: 0x00..0xFFFF
  @type long :: 0x00..0xFFFFFF
  @type address :: 0x00..0xFFFFFF

  @spec format_byte(byte()) :: String.t()
  def format_byte(byte) when is_integer(byte) and byte >= 0x00 and byte <= 0xFF do
    "$" <> format_data(byte, 2)
  end

  @spec format_word(word()) :: String.t()
  def format_word(word) when is_integer(word) and word >= 0x0000 and word <= 0xFFFF do
    "$" <> format_data(word, 4)
  end

  @spec format_long(long()) :: String.t()
  def format_long(long) when is_integer(long) and long >= 0x000000 and long <= 0xFFFFFF do
    "$" <> format_data(long, 6)
  end

  defp format_data(data, length) do
    data
    |> Integer.to_string(16)
    |> String.pad_leading(length, "0")
  end
end
