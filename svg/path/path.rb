require_relative 'directions/direction'
require_relative 'directions/move_to'
require_relative 'directions/line_to'
require_relative 'directions/horizontal_to'
require_relative 'directions/vertical_to'
require_relative 'directions/quadratic_curve_to'
require_relative 'directions/cubic_curve_to'
require_relative 'directions/arc_to'
require_relative 'directions/close_path'

class Path
  attr_accessor :directions, :start, :finish, :d

  DIRECTIONS = {
      m: MoveTo,
      l: LineTo,
      h: HorizontalTo,
      v: VerticalTo,
      c: CubicCurveTo,
      s: CubicCurveTo,
      q: QuadraticCurveTo,
      t: QuadraticCurveTo,
      a: ArcTo,
      z: ClosePath
  }

  def initialize(d='')
    @d = d
    @directions = []
  end

  def organize!(point=nil)
    if point.nil?
      @start = directions.first.finish
      directions.first.start = directions.first.finish
    else
      @start = point
      directions.first.start = point
    end
    directions.first.absolute!(@start)
    directions.each_index do |i|
      next if i==0
      directions[i].absolute!(directions[i-1].finish)
    end
    if directions.last.is_a? ClosePath
      start_point = directions[-2].finish
      directions[-1] = LineTo.new 'L', [@start.x, @start.y]
      directions[-1].start = start_point
    end
    @finish = directions.last.finish
    self
  end

  def d
    @d = ''
    directions.each do |direction|
      @d << direction.to_command
    end
    @d
  end

  def dimensions
    max_x = -Float::INFINITY
    max_y = -Float::INFINITY

    min_x = Float::INFINITY
    min_y = Float::INFINITY

    directions.each do |direction|
      next if direction.is_a? MoveTo
      next if direction.is_a? ClosePath
      max_x = direction.start.x if max_x < direction.start.x
      max_y = direction.start.y if max_y < direction.start.y

      max_x = direction.finish.x if max_x < direction.finish.x
      max_y = direction.finish.y if max_y < direction.finish.y

      min_x = direction.start.x if min_x > direction.start.x
      min_y = direction.start.y if min_y > direction.start.y

      min_x = direction.finish.x if min_x > direction.finish.x
      min_y = direction.finish.y if min_y > direction.finish.y
    end
    [min_x, min_y, max_x, max_y]
  end

  def split(size)
    spath = Path.new
    directions.each do |direction|
      spath.directions+= direction.split size
    end
    spath.organize!(spath.directions.first.finish)
    spath
  end

  def length

  end

  class << self
    def parse(d)
      raise TypeError unless d.is_a? String
      subpaths = extract_subpaths d
      raise TypeError if subpaths.empty?
      paths = []
      subpaths.each do |subpath|
        next_path = parse_subpath(subpath).organize!
        paths << next_path
      end
      paths
    end

    private
    def extract_subpaths(d)
      subpaths = []
      move_index = d.index(/[Mm]/)

      if move_index != nil
        subpaths << d[0...move_index] if move_index > 0
        d.scan(/[Mm](?:\d|[eE.,+-]|[LlHhVvQqCcTtSsAaZz]|\W)+/m) do
          subpaths << $&
        end
      else
        subpaths << d
      end
      subpaths
    end

    def parse_subpath(d)
      path = Path.new
      path.d = d
      path.directions = extract_directions(d) || []
      unless path.directions.empty?
        if path.directions.first.is_a? MoveTo
          path.start = path.directions.first.finish
        else
          path.start = path.directions.first.start
        end
        path.finish = path.directions.last.finish
      end
      path
    end

    def extract_directions(d)
      directions = []
      d.scan(/[MmLlHhVvQqCcTtSsAaZz](?:\d|[eE.,+-]|\W)*/m) do
        directions << build_direction($&)
      end
      directions.flatten
    end

    def build_direction(d)
      command_code = d[0]
      coordinates = extract_coordinates d
      DIRECTIONS[command_code.downcase.to_sym].new(command_code, coordinates)
    end

    def extract_coordinates(command_string)
      coordinates = []
      command_string.scan(/-?\d+(\.\d+)?([eE][+-]?\d+)?/) do
        coordinates << $&.to_f
      end
      coordinates
    end
  end
end