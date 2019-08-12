defmodule Util.PageTest do
  use ExUnit.Case
  import Util.Test.DataBuilder

  test "new with exactly a page worth of data returns a page" do
    data = build_block_of_ffs(Util.Page.page_size())
    assert %Util.Page{} = Util.Page.new(data)
  end

  test "new with more than a page worth of data returns a page and the excess data" do
    data = build_block_of_ffs(Util.Page.page_size() + 5)
    assert {%Util.Page{}, remainder} = Util.Page.new(data)
    assert byte_size(remainder) == 5
  end

  test "get_byte returns the byte requested" do
    data = <<0xDE, 0xAD, 0xBE, 0xEF>> <> build_block_of_ffs(Util.Page.page_size() - 4)
    page = Util.Page.new(data)
    assert 0xDE == Util.Page.get_byte(page, 0)
    assert 0xAD == Util.Page.get_byte(page, 1)
    assert 0xBE == Util.Page.get_byte(page, 2)
    assert 0xEF == Util.Page.get_byte(page, 3)
    assert 0xFF == Util.Page.get_byte(page, 4)
  end

  test "get_block/2 returns the block requested" do
    beginning = <<0xDE, 0xAD, 0xBE, 0xEF>>
    middle = build_block_of_ffs(Util.Page.page_size() - 68)
    ending = build_final_fantasy_2_header()
    data = beginning <> middle <> ending

    page = Util.Page.new(data)
    assert data == Util.Page.get_block(page, 0)
    assert <<0xBE, 0xEF>> <> middle <> ending == Util.Page.get_block(page, 2)
    assert ending == Util.Page.get_block(page, 0xFC0)
  end

  test "get_block/3 returns the block requested" do
    beginning = <<0xDE, 0xAD, 0xBE, 0xEF>>
    middle = build_block_of_ffs(Util.Page.page_size() - 68)
    ending = build_final_fantasy_2_header()
    data = beginning <> middle <> ending

    page = Util.Page.new(data)
    assert data == Util.Page.get_block(page, 0, Util.Page.page_size())
    assert <<0xDE, 0xAD, 0xBE, 0xEF>> == Util.Page.get_block(page, 0, 4)
    assert ending == Util.Page.get_block(page, 0xFC0, 64)
    assert middle == Util.Page.get_block(page, 4, Util.Page.page_size() - 68)
  end
end
