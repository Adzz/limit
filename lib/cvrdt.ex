defprotocol CVRDT do
  def increment(a)
  def value(a)
  def join(a, b)
end
