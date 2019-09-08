defmodule Sneex.Address.CycleCalculatorTest do
  use ExUnit.Case
  alias Sneex.Address.CycleCalculator
  alias Sneex.{Cpu, Memory}

  setup do
    {:ok, cpu: <<>> |> Memory.new() |> Cpu.new() |> Cpu.emu_mode(:native)}
  end

  # Construct each instance and run it once to see it pass and once to see it fail
  test "constant/1" do
    assert %CycleCalculator{cycles: 6, check_func: f} = 6 |> CycleCalculator.constant()
    assert true == f.("foo")
    assert true == f.("bar")
    assert true == f.(%{foo: "bar"})
  end

  test "acc_is_16_bit/1", %{cpu: cpu} do
    assert %CycleCalculator{cycles: 2, check_func: f} = 2 |> CycleCalculator.acc_is_16_bit()

    cpu = cpu |> Cpu.acc_size(:bit8)
    assert false == f.(cpu)

    cpu = cpu |> Cpu.acc_size(:bit16)
    assert true == f.(cpu)
  end

  test "index_is_16_bit/1", %{cpu: cpu} do
    assert %CycleCalculator{cycles: 1, check_func: f} = 1 |> CycleCalculator.index_is_16_bit()

    cpu = cpu |> Cpu.index_size(:bit8)
    assert false == f.(cpu)

    cpu = cpu |> Cpu.index_size(:bit16)
    assert true == f.(cpu)
  end

  test "native_mode/1", %{cpu: cpu} do
    assert %CycleCalculator{cycles: 3, check_func: f} = 3 |> CycleCalculator.native_mode()

    cpu = cpu |> Cpu.emu_mode(:emulation)
    assert false == f.(cpu)

    cpu = cpu |> Cpu.emu_mode(:native)
    assert true == f.(cpu)
  end

  test "low_direct_page_is_not_zero/1", %{cpu: cpu} do
    assert %CycleCalculator{cycles: 4, check_func: f} =
             4 |> CycleCalculator.low_direct_page_is_not_zero()

    cpu = cpu |> Cpu.direct_page(0xFF00)
    assert false == f.(cpu)

    cpu = cpu |> Cpu.direct_page(0xAABB)
    assert true == f.(cpu)
  end

  describe "check_page_boundary/3" do
    setup %{cpu: cpu} do
      cpu = cpu |> Cpu.index_size(:bit16)
      {:ok, cpu: cpu}
    end

    test "index by x", %{cpu: cpu} do
      assert %CycleCalculator{cycles: 1, check_func: f} =
               1 |> CycleCalculator.check_page_boundary(0x0195, :x)

      assert false == cpu |> Cpu.x(0x0028) |> f.()
      assert true == cpu |> Cpu.x(0x0088) |> f.()
    end

    test "index by y", %{cpu: cpu} do
      assert %CycleCalculator{cycles: 1, check_func: f} =
               1 |> CycleCalculator.check_page_boundary(0x0195, :y)

      assert false == cpu |> Cpu.y(0x0028) |> f.()
      assert true == cpu |> Cpu.y(0x0088) |> f.()
    end
  end

  test "check_page_boundary_and_emulation_mode/3 - cross page", %{cpu: cpu} do
    assert %CycleCalculator{cycles: 1, check_func: f} =
             1 |> CycleCalculator.check_page_boundary_and_emulation_mode(0x0100, 0x0200)

    cpu = cpu |> Cpu.emu_mode(:native)
    assert false == f.(cpu)

    cpu = cpu |> Cpu.emu_mode(:emulation)
    assert true == f.(cpu)
  end

  test "check_page_boundary_and_emulation_mode/3 - same page", %{cpu: cpu} do
    assert %CycleCalculator{cycles: 1, check_func: f} =
             1 |> CycleCalculator.check_page_boundary_and_emulation_mode(0x0100, 0x0150)

    cpu = cpu |> Cpu.emu_mode(:native)
    assert false == f.(cpu)

    cpu = cpu |> Cpu.emu_mode(:emulation)
    assert false == f.(cpu)
  end

  test "calc_cycles/2", %{cpu: cpu} do
    cpu = cpu |> Cpu.acc_size(:bit8) |> Cpu.index_size(:bit8)

    mods = [
      CycleCalculator.constant(4),
      CycleCalculator.constant(3),
      CycleCalculator.acc_is_16_bit(2),
      CycleCalculator.index_is_16_bit(1)
    ]

    # Both 8-bit, so should be 7 (4+3)
    assert 7 == CycleCalculator.calc_cycles(cpu, mods)

    # Acc 16-bit, index 8-bit, so should be 9 (4+3+2)
    cpu = cpu |> Cpu.acc_size(:bit16)
    assert 9 == CycleCalculator.calc_cycles(cpu, mods)

    # Both 16-bit, so should be 10 (4+3+2+1)
    cpu = cpu |> Cpu.index_size(:bit16)
    assert 10 == CycleCalculator.calc_cycles(cpu, mods)
  end
end
