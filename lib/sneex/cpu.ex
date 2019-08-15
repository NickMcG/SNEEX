defmodule Sneex.Cpu do
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
    :program_counter
  ]

  @opaque t :: %Sneex.Cpu{
            accumulator: Sneex.BasicTypes.word(),
            index_x: Sneex.BasicTypes.word(),
            index_y: Sneex.BasicTypes.word(),
            data_bank_register: Sneex.BasicTypes.byte(),
            direct_page_register: Sneex.BasicTypes.word(),
            program_bank_register: Sneex.BasicTypes.byte(),
            stack_pointer: Sneex.BasicTypes.word(),
            processor_status: 0x00..0x1FF,
            program_counter: Sneex.BasicTypes.word()
          }

  # Design thoughts:
  # - CPU should have 2 functions:
  #     - tick: this will act as a clock tick
  #     - step: this will immediately execute the current command (regardless of remaining ticks)
  # - Have a module that will load the next command
  # - Have a module/struct that represents current command
end
