require_relative 'directions/move_to'
require_relative 'directions/line_to'
require_relative 'directions/horizontal_to'
require_relative 'directions/vertical_to'
require_relative 'directions/cubic_curve_to'
require_relative 'directions/quadratic_curve_to'
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

  def organize!
    self
  end

  class << self
    def parse(d)
      raise TypeError unless d.kind_of? String
      subpaths = extract_subpaths d
      raise TypeError if subpaths.empty?
      paths = []
      subpaths.each do |subpath|
        paths << parse_subpath(subpath).organize!
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
      path.directions = extract_directions(d) || []
      unless path.directions.empty?
        path.start = path.directions.first.start
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