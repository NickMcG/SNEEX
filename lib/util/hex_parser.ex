defmodule Util.HexParser do
  def convert_file() do
    # Default to 2 files
    convert_file("C:/code/sneex/roms/FF_II.sfc", "C:/code/sneex/roms/FF_II_dump.txt")
  end

  def convert_file(input_file, output_file) do
    input_file
    |> File.open!([:read, :binary], &input_handler/1)
    |> write_output(output_file)
  end

  defp write_output(contents, output_file) do
    File.write!(output_file, contents)
  end

  defp input_handler(input_pid) do
    input_pid
    |> read_file([])
    |> Enum.reduce("", &format_result/2)
  end

  defp read_file(input_pid, result_list) do
    case read_block(input_pid) do
      :eof ->
        result_list
      block ->
        index = Enum.count(result_list) * 16
        read_file(input_pid, [{index, block} | result_list])
    end
  end

  # Block is 16 bytes - this is representative of 1 line of text in the output
  defp read_block(input_pid) do
    IO.binread(input_pid, 16)
  end

  defp format_result({index, block}, result) do
    "#{format_index(index)}: #{format_block(block)}\r\n#{result}"
  end

  defp format_block(<<
        b0 :: size(8), b1 :: size(8), b2 :: size(8), b3 :: size(8),
        b4 :: size(8), b5 :: size(8), b6 :: size(8), b7 :: size(8),
        b8 :: size(8), b9 :: size(8), bA :: size(8), bB :: size(8),
        bC :: size(8), bD :: size(8), bE :: size(8), bF :: size(8)
  >>) do
    fhex = &(format_byte(&1, 16, 2))
    fbin = &(format_printable_byte(&1))

    hex1 = "#{fhex.(b0)} #{fhex.(b1)} #{fhex.(b2)} #{fhex.(b3)}"
    hex2 = "#{fhex.(b4)} #{fhex.(b5)} #{fhex.(b6)} #{fhex.(b7)}"
    hex3 = "#{fhex.(b8)} #{fhex.(b9)} #{fhex.(bA)} #{fhex.(bB)}"
    hex4 = "#{fhex.(bC)} #{fhex.(bD)} #{fhex.(bE)} #{fhex.(bF)}"

    bin1 = "#{fbin.(b0)}#{fbin.(b1)}#{fbin.(b2)}#{fbin.(b3)}"
    bin2 = "#{fbin.(b4)}#{fbin.(b5)}#{fbin.(b6)}#{fbin.(b7)}"
    bin3 = "#{fbin.(b8)}#{fbin.(b9)}#{fbin.(bA)}#{fbin.(bB)}"
    bin4 = "#{fbin.(bC)}#{fbin.(bD)}#{fbin.(bE)}#{fbin.(bF)}"

    "#{hex1} #{hex2}  #{hex3} #{hex4}  |#{bin1}#{bin2}#{bin3}#{bin4}|"
  end

  defp format_byte(byte, base, length) do
    byte
    |> Integer.to_string(base)
    |> String.pad_leading(length, "0")
  end

  defp format_printable_byte(byte) when byte >= 32 and byte <= 127 do
    case String.valid?(to_string([byte])) do
      true -> [byte]
      _ -> "."
    end
  end

  defp format_printable_byte(_byte) do
    "."
  end

  defp format_index(index) do
    <<bank :: binary-size(2), remainder :: binary>> =
      index
      |> Integer.to_string(16)
      |> String.pad_leading(6, "0")

    bank <> " " <> remainder
  end
end
