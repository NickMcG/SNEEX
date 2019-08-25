defprotocol Sneex.Ops.Opcode do
  @type t :: %Sneex.Ops.Increment{}

  @spec byte_size(__MODULE__.t()) :: 1 | 2 | 3 | 4
  def byte_size(opcode)

  @spec total_cycles(__MODULE__.t(), Sneex.Cpu.t()) :: pos_integer()
  def total_cycles(opcode, cpu)

  @spec execute(__MODULE__.t(), Sneex.Cpu.t()) :: Sneex.Cpu.t()
  def execute(opcode, cpu)

  @spec disasm(__MODULE__.t(), Sneex.Memory.t(), Sneex.BasicTypes.address()) :: String.t()
  def disasm(opcode, memory, address)
end
