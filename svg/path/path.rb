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

  def initialize(d=[])
    @d = d
    @directions = []
  end

  def organize!(point=nil)
    unless point.nil?
      @start = point
      directions.first.start = point
    end
    directions.first.absolute!(@start)
    directions.each_index do |i|
      next if i==0
      directions[i].absolute!(directions[i-1].finish)
    end

    @finish = directions.last.finish
    self
  end

  def length

  end

  class << self
    def parse(d)
      raise TypeError unless d.is_a? String
      subpaths = extract_subpaths d
      raise TypeError if subpaths.empty?
      paths = []
      last_point = nil
      subpaths.each do |subpath|
        next_path = parse_subpath(subpath).organize!(last_point)
        paths << next_path
        last_point = next_path.directions.last.finish
      end
      paths
    end

    private
    def extract_subpaths(d)
      subpaths = []
      move_index = d.index(/[Mm]/)

      if move_index != nil
        subpaths << d[0...move_index] if move_index > 0
        d.scan(/[Mm](?:\d|[eE.,+-]|[LlHhVvQqCcTtSsAaZz]|\W)+/m) do |match_group|
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