require_relative 'direction'
class ClosePath < Direction

  def absolute!(start_point=nil)
    command_code.upcase!
    self
  end
end