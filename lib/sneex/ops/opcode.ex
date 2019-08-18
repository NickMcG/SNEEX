defprotocol Sneex.Ops.Opcode do
  @spec byte_size(any()) :: 1 | 2 | 3 | 4
  def byte_size(opcode)

  @spec total_cycles(any(), Sneex.CpuState.t()) :: pos_integer()
  def total_cycles(opcode, cpu)

  @spec execute(any(), Sneex.CpuState.t(), Sneex.Memory.t()) ::
          {Sneex.CpuState.t(), Sneex.Memory.t()}
  def execute(opcode, cpu, memory)

  @spec disasm(any(), Sneex.Memory.t(), Sneex.BasicTypes.address()) :: String.t()
  def disasm(opcode, memory, address)
end
