defprotocol Sneex.Ops.Opcode do
  @type t :: %Sneex.Ops.Increment{}

  @spec byte_size(__MODULE__.t()) :: 1 | 2 | 3 | 4
  def byte_size(opcode)

  @spec total_cycles(__MODULE__.t(), Sneex.CpuState.t()) :: pos_integer()
  def total_cycles(opcode, cpu)

  @spec execute(__MODULE__.t(), Sneex.CpuState.t(), Sneex.Memory.t()) ::
          {Sneex.CpuState.t(), Sneex.Memory.t()}
  def execute(opcode, cpu, memory)

  @spec disasm(__MODULE__.t(), Sneex.Memory.t(), Sneex.BasicTypes.address()) :: String.t()
  def disasm(opcode, memory, address)
end
