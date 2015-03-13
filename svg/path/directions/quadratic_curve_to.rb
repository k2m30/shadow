class QuadraticCurveTo < Direction

  def split(size, last_curve_point=nil)
    n = 4

    x0 = position.x
    y0 = position.y

    if @control
      x1 = @control.x
      y1 = @control.y
    else
      p position
      p last_curve_point
      x1 = 2 * position.x - last_curve_point.x
      y1 = 2 * position.y - last_curve_point.y
    end

    x2 = target.x
    y2 = target.y

    #if curve is too small - just change it to line
    if (length(x0, y0, x1, y1) < size/n) && (length(x1, y1, x2, y2) < size/n) &&
        (length(x0, y0, x2, y2) < size/n)
      return [LineTo.new('L', [x2, y2])]
    end

    #### detecting proper differentiation value
    max_length = nil

    begin
      last_x = x0
      last_y = y0
      max_length = 0
      n=(n*1.2).round
      dt = 1.0/n
      t = dt

      n.times do
        x = (1 - t) * (1 - t) * x0 + 2 * t * (1 - t) * x1 + t * t * x2
        y = (1 - t) * (1 - t) * y0 + 2 * t * (1 - t) * y1 + t * t * y2
        length = Math.sqrt((x-last_x)**2+(y-last_y)**2)
        max_length = length if length > max_length
        t+=dt
        last_x = x
        last_y = y
      end
    end while max_length > size

    ####

    dt = 1.0/n
    t = dt

    result = []
    (n-1).times do
      x = (1 - t) * (1 - t) * x0 + 2 * t * (1 - t) * x1 + t * t * x2
      y = (1 - t) * (1 - t) * y0 + 2 * t * (1 - t) * y1 + t * t * y2
      result << LineTo.new('L', [x, y])
      t+=dt
    end
    t = 1
    x = (1 - t) * (1 - t) * x0 + 2 * t * (1 - t) * x1 + t * t * x2
    y = (1 - t) * (1 - t) * y0 + 2 * t * (1 - t) * y1 + t * t * y2
    result << LineTo.new('L', [x, y])

  end

end