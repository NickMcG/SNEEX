defmodule Util.BankTest do
  use ExUnit.Case
  import Util.Test.DataBuilder

  test "new with exactly a bank worth of data returns a bank" do
    data = build_block_of_ffs(Util.Bank.bank_size())
    assert %Util.Bank{} = Util.Bank.new(data)
  end

  test "new with more than a bank worth of data returns a bank and the excess data" do
    data = build_block_of_ffs(Util.Bank.bank_size() + 5)
    assert {%Util.Bank{}, remainder} = Util.Bank.new(data)
    assert byte_size(remainder) == 5
  end

  test "extract_header with the header on page 7 returns the header" do
    bank = Util.Bank.new(build_data_for_bank_with_header_on_page_7())
    assert %Util.Header{} = Util.Bank.extract_header(bank)
  end

  test "extract_header with the header on page F returns the header" do
    bank = Util.Bank.new(build_data_for_bank_with_header_on_page_f())
    assert %Util.Header{} = Util.Bank.extract_header(bank)
  end

  test "extract_header without a header returns nil" do
    bank = Util.Bank.new(build_data_for_bank_without_header())
    assert nil == Util.Bank.extract_header(bank)
  end
end
