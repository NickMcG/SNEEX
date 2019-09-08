defprotocol Sneex.Address.Mode do
  @spec address(any()) :: Sneex.BasicTypes.long()
  def address(mode)

  @spec byte_size(any()) :: 0 | 1 | 2 | 3
  def byte_size(mode)

  @spec fetch(any(), Sneex.Cpu.t()) :: byte() | Sneex.BasicTypes.word() | Sneex.BasicTypes.long()
  def fetch(mode, cpu)

  @spec store(any(), Sneex.Cpu.t(), byte() | Sneex.BasicTypes.word() | Sneex.BasicTypes.long()) ::
          Sneex.Cpu.t()
  def store(mode, cpu, data)

  @spec disasm(any(), Sneex.Cpu.t()) :: String.t()
  def disasm(mode, cpu)
end
