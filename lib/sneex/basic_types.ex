defmodule Sneex.BasicTypes do
  @moduledoc """
  This module defines some basic data types that are used across the application.
  """

  @type word :: 0x00..0xFFFF
  @type long :: 0x00..0xFFFFFF
  @type address :: 0x00..0xFFFFFF
end
