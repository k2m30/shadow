class MoveTo < Direction
  def split(size)
    [Direction.new(command_code, [start.x.round(2), start.y.round(2)])]
  end
  def length
    nil
  end
end