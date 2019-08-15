defmodule Sneex.Memory do
  @moduledoc """
  This module wraps memory access.
  """
  defstruct [:data]

  use Bitwise

  @opaque t :: %__MODULE__{
            data: binary()
          }

  @spec new(binary()) :: __MODULE__.t()
  def new(data) when is_binary(data) do
    %__MODULE__{data: data}
  end

  @spec load_byte(__MODULE__.t(), Sneex.BasicTypes.address()) :: byte()
  def load_byte(%__MODULE__{data: data}, address) do
    load_data(data, address, 1)
  end

  @spec load_word(__MODULE__.t(), Sneex.BasicTypes.address()) :: Sneex.BasicTypes.word()
  def load_word(%__MODULE__{data: data}, address) do
    load_data(data, address, 2)
  end

  @spec load_long(__MODULE__.t(), Sneex.BasicTypes.address()) :: Sneex.BasicTypes.long()
  def load_long(%__MODULE__{data: data}, address) do
    load_data(data, address, 3)
  end

  defp load_data(memory, 0, length) when is_binary(memory) and length < byte_size(memory) do
    <<data::binary-size(length), _rest::binary>> = memory
    data |> format_data
  end

  defp load_data(memory, address, length)
       when is_binary(memory) and address + length <= byte_size(memory) do
    <<_before::binary-size(address), data::binary-size(length), _rest::binary>> = memory
    data |> format_data
  end

  defp format_data(<<b::size(8)>>), do: b

  defp format_data(<<b0::size(8), b1::size(8)>>) do
    b1 <<< 8 ||| b0
  end

  defp format_data(<<b0::size(8), b1::size(8), b2::size(8)>>) do
    b2 <<< 16 ||| b1 <<< 8 ||| b0
  end
end
