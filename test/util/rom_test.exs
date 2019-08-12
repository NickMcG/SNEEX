defmodule Util.RomTest do
  use ExUnit.Case
  import Util.Test.DataBuilder

  test "parse" do
    first_bank = build_data_for_bank_with_header_on_page_7() |> Util.Bank.new()
    other_bank = build_data_for_bank_without_header() |> Util.Bank.new()

    banks = %{0x00 => first_bank, 0x01 => other_bank}

    assert %Util.Rom{} = Util.Rom.new(banks)
  end
end
