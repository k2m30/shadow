class CubicCurveTo < Direction
  def split(size, last_curve_point=nil)
    n = 4 #start number of pieces value

    x0 = position.x
    y0 = position.y

    if @control_1
      x1 = @control_1.x
      y1 = @control_1.y
    else
      x1 = 2 * position.x - last_curve_point.x
      y1 = 2 * position.y - last_curve_point.y
    end

    x2 = control_2.x
    y2 = control_2.y

    x3 = target.x
    y3 = target.y

    #if curve is too small - just change it to line
    if (length(x0, y0, x1, y1) < size) && (length(x1, y1, x2, y2) < size) &&
        (length(x2, y2, x3, y3) < size) && (length(x0, y0, x3, y3) < size)
      return [Savage::Directions::LineTo.new(x3, y3)]
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
        x = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t) * x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3
        y = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t) * y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3
        length = Math.sqrt((x-last_x)*(x-last_x)+(y-last_y)*(y-last_y))
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
      x = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t) * x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3
      y = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t) * y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3
      result << Savage::Directions::LineTo.new(x, y)
      t+=dt
    end
    t = 1
    x = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t) * x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3
    y = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t) * y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3
    result << Savage::Directions::LineTo.new(x, y)

  end


end