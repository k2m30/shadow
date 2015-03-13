class Path
  attr_accessor :directions, :start, :finish, :d

  DIRECTIONS = {
      m: {class: MoveTo,
          args: 2},
      l: {class: LineTo,
          args: 2},
      h: {class: HorizontalTo,
          args: 1},
      v: {class: VerticalTo,
          args: 1},
      c: {class: CubicCurveTo,
          args: 6},
      s: {class: CubicCurveTo,
          args: 4},
      q: {class: QuadraticCurveTo,
          args: 4},
      t: {class: QuadraticCurveTo,
          args: 2},
      a: {class: ArcTo,
          args: 7}
  }

  def initialize(d=[])
    @d = d
    @directions = []
  end

  def self.parse(d)
    raise TypeError unless d.kind_of? String
    subpaths = extract_subpaths d
    raise TypeError if subpaths.empty?
    paths = []
    subpaths.each do |subpath|
      paths << parse_subpath(subpath)
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

  def parse_subpath(d, force_absolute=true)
    path = Path.new
    path.directions = extract_directions d, force_absolute || []
    unless path.directions.empty?
      path.start = path.directions.first.start
      path.finish = path.directions.last.finish
    end
    path
  end

  def extract_directions(d, force_absolute)
    directions = []
    d.scan(/[MmLlHhVvQqCcTtSsAaZz](?:\d|[eE.,+-]|\W)*/m) do
      directions << build_direction($&, force_absolute)
    end
    directions.flatten
  end

  def build_direction(d, force_absolute)
    directions = []
    recurse_code = d[0..1].gsub(' ')
    coordinates = extract_coordinates d
    directions << construct_direction(recurse_code, coordinates, force_absolute)
  end

  def extract_coordinates(command_string)
    coordinates = []
    command_string.scan(/-?\d+(\.\d+)?([eE][+-]?\d+)?/) do
      coordinates << $&.to_f
    end
    coordinates
  end

  def construct_direction(recurse_code, coordinates, absolute)
    raise TypeError if args.any?(&:nil?)
    DIRECTIONS[recurse_code][:class].new(coordinates, absolute)
  end


end