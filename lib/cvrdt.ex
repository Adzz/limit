defprotocol CVRDT do
  def increment(a)
  def increment(a, fun)
  def value(a)
  def join(a, b)
end
