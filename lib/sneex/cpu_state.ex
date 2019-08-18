defmodule Sneex.CpuState do
  @moduledoc """
  This module defines a structure that represents the CPU's current state, and defines functions for
  interacting with that state (getting it, updating it, etc.).
  """
  defstruct [
    :accumulator,
    :index_x,
    :index_y,
    :data_bank_register,
    :direct_page_register,
    :program_bank_register,
    :stack_pointer,
    :processor_status,
    :program_counter,
    :emulation_mode
  ]

  @type t :: %__MODULE__{
          accumulator: Sneex.BasicTypes.word(),
          index_x: Sneex.BasicTypes.word(),
          index_y: Sneex.BasicTypes.word(),
          data_bank_register: byte(),
          direct_page_register: Sneex.BasicTypes.word(),
          program_bank_register: byte(),
          stack_pointer: Sneex.BasicTypes.word(),
          processor_status: 0x00..0xFF,
          program_counter: Sneex.BasicTypes.word(),
          emulation_mode: :native | :emulation | nil
        }

  # Design thoughts:
  # - CPU should have 2 functions:
  #     - tick: this will act as a clock tick
  #     - step: this will immediately execute the current command (regardless of remaining ticks)
  # - Have a module that will load the next command
  # - Have a module/struct that represents current command
end

# 23                    15                       7                         0
#                       Accumulator (B)      (A) or (C)      Accumulator (A)
# Data Bank Register
#                       X Index                  Register X
#                       Y Index                  Register Y
#   0 0 0 0 0 0 0 0     Direct                   Page Register (D)
#   0 0 0 0 0 0 0 0     Stack                    Pointer (S)
# Program Bank Register Program                  Counter (PC)

# 7: Negative
# 6: Overflow
# 5: Memory/Accumulator Select (1 = 8-bit, 0 = 16-bit)
# 4: Index Register Select (1 = 8-bit, 0 = 16-bit)
# 3: Decimal mode (1 = Decimal, 0 = Binary)
# 2: IRQ Disable (1 = Disabled)
# 1: Zero (1 = Zero Result)
# 0: Carry (1 = Carry)
