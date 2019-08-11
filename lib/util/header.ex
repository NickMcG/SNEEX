defmodule Util.Header do
  @moduledoc """
  This module defines a structure for interpretting some of the ROM's metadata
  """

  use Bitwise

  @base_size 0x400

  defstruct [
    :title,
    :rom_makeup,
    :rom_type,
    :rom_size,
    :sram_size,
    :license_id,
    :version_number,
    :interrupts
  ]

  @type rom_makeup :: :lorom | :hirom | :sa1rom | :lofastrom | :hifastrom | :exlorom | :exhirom
  @type rom_type :: :rom | :ram | :sram | :dsp1 | :fx

  @type t :: %Util.Header{
          title: String.t(),
          rom_makeup: rom_makeup(),
          rom_type: rom_type(),
          rom_size: non_neg_integer(),
          sram_size: non_neg_integer(),
          license_id: integer(),
          version_number: integer(),
          interrupts: nil
        }

  def new do
    %Util.Header{
      title: "TODO",
      rom_makeup: :lorom,
      rom_type: :rom,
      rom_size: 42,
      sram_size: 42,
      license_id: 42,
      version_number: 42
    }
  end

  @spec new(binary()) :: Util.Header.t() | :invalid
  def new(<<
        raw_title::binary-size(21),
        raw_rom_makeup::binary-size(1),
        raw_rom_type::binary-size(1),
        raw_rom_size::size(8),
        raw_sram_size::size(8),
        license_id::size(8),
        version::size(8),
        _checksum_complement::size(16),
        _checksum::size(16),
        _unknown::binary-size(1),
        _native_vectors::binary-size(16),
        _emulation_vectors::binary-size(16)
      >>) do
    with {:ok, title} <- determine_title(raw_title),
         {:ok, rom_makeup} <- determine_rom_makeup(raw_rom_makeup),
         {:ok, rom_type} <- determine_rom_type(raw_rom_type),
         rom_size <- determine_size(raw_rom_size),
         sram_size <- determine_size(raw_sram_size) do
      %Util.Header{
        title: title,
        rom_makeup: rom_makeup,
        rom_type: rom_type,
        rom_size: rom_size,
        sram_size: sram_size,
        license_id: license_id,
        version_number: version
      }
    else
      _ -> :invalid
    end
  end

  defp determine_title(raw_title) do
    case String.valid?(raw_title) do
      true ->
        title = raw_title |> String.codepoints() |> List.to_string() |> String.trim()
        {:ok, title}

      _ ->
        :invalid
    end
  end

  defp determine_rom_makeup(<<0x20>>), do: {:ok, :lorom}
  defp determine_rom_makeup(<<0x21>>), do: {:ok, :hirom}
  defp determine_rom_makeup(<<0x23>>), do: {:ok, :sa1rom}
  defp determine_rom_makeup(<<0x30>>), do: {:ok, :lofastrom}
  defp determine_rom_makeup(<<0x31>>), do: {:ok, :hifastrom}
  defp determine_rom_makeup(<<0x32>>), do: {:ok, :exlorom}
  defp determine_rom_makeup(<<0x35>>), do: {:ok, :exhirom}
  defp determine_rom_makeup(_), do: :invalid

  # eventually figure this out...
  defp determine_rom_type(_), do: {:ok, :rom}

  defp determine_size(raw_size) do
    @base_size <<< raw_size
  end
end
