defmodule Sneex.CpuHelper do
  @moduledoc "This module defines helper functions for checking CPU flags."

  @doc "
  This function will determine new values for several of the CPU flags.

  ## Examples

  iex> 0 |> Sneex.CpuHelper.check_flags_for_value(:bit8)
  %{carry: false, negative: false, overflow: false, zero: true}

  iex> 0 |> Sneex.CpuHelper.check_flags_for_value(:bit16)
  %{carry: false, negative: false, overflow: false, zero: true}

  iex> 0x80|> Sneex.CpuHelper.check_flags_for_value(:bit8)
  %{carry: false, negative: true, overflow: false, zero: false}

  iex> 0x80 |> Sneex.CpuHelper.check_flags_for_value(:bit16)
  %{carry: false, negative: false, overflow: false, zero: false}

  iex> 0x7FFF |> Sneex.CpuHelper.check_flags_for_value(:bit16)
  %{carry: false, negative: false, overflow: false, zero: false}

  iex> 0x8000 |> Sneex.CpuHelper.check_flags_for_value(:bit16)
  %{carry: false, negative: true, overflow: false, zero: false}
  "
  @spec check_flags_for_value(integer(), Sneex.Cpu.bit_size()) :: %{
          carry: boolean(),
          negative: boolean(),
          overflow: boolean(),
          zero: boolean()
        }
  def check_flags_for_value(value, bitness) do
    %{
      negative: check_negative_flag(value, bitness),
      overflow: check_overflow_flag(value),
      zero: check_zero_flag(value),
      carry: check_carry_flag(value)
    }
  end

  defp check_negative_flag(value, :bit8) when value >= 0x80, do: true
  defp check_negative_flag(value, :bit16) when value >= 0x8000, do: true
  defp check_negative_flag(_value, _bitness), do: false

  # Still need to figure this out
  defp check_overflow_flag(_value), do: false

  defp check_zero_flag(0), do: true
  defp check_zero_flag(_), do: false

  # Still need to figure this out
  defp check_carry_flag(_value), do: false
end
