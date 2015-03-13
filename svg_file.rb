require 'nokogiri'
require 'yaml'
require 'open-uri'


class SVGFile
  attr_reader :paths, :properties, :whole_path, :tpath, :splitted_path

  def initialize(file_name, properties_file_name = 'properties.yml')
    @allowed_elements = ['path']

    read_svg file_name
    absolute!
    close_paths!
    read_properties! properties_file_name
    read_whole_path!
    split!
    make_tpath!
    highlight_arris!
  end

  def close_paths!
    @paths.each do |path|
      path.subpaths.each do |subpath|
        if subpath.directions.last.kind_of? Savage::Directions::ClosePath
          point = find_first_point(subpath)
          subpath.directions[-1] = Savage::Directions::LineTo.new(point.x, point.y) unless point == subpath.directions[-2].target
        end
      end
    end
  end

  def split!
    @splitted_path = Savage::Path.new
    size = @properties['max_segment_length']
    @whole_path.directions.each_with_index do |direction, i|
      if %w[S s T t].include? direction.command_code # smooth curves need second control point of previous curve
        new_directions = direction.split size, @whole_path.directions[i-1].control_2
      else
        new_directions = direction.split size
      end

      subpath = Savage::SubPath.new
      subpath.directions = new_directions
      @splitted_path.subpaths << subpath
    end
  end

  def read_svg(file_name)
    @paths = []
    elements = []
    svg = Nokogiri::XML open file_name
    svg.traverse do |e|
      elements.push e if e.element? && @allowed_elements.include?(e.name)
    end
    elements.map do |e|
      @paths.push e.attribute_nodes.select { |a| a.name == 'd' }
    end
    @paths.flatten!.map!(&:value).map! { |path| Savage::Parser.parse path }
    @width = svg.at_css('svg')[:width].to_f
    @height = svg.at_css('svg')[:height].to_f
  end

  def read_properties!(file_name)
    @properties = File.open(file_name) { |yf| YAML::load(yf) }
  end

  def read_whole_path!
    @whole_path = Savage::Path.new
    @whole_path.subpaths = []
    @paths.each do |path|
      path.subpaths.each do |subpath|
        new_subpath = Savage::SubPath.new
        new_subpath.directions = subpath.directions
        new_subpath.directions.delete_if { |d| d.is_a?(Savage::Directions::ClosePath) }
        @whole_path.subpaths << new_subpath
      end
    end
    @whole_path.optimize!(@properties['initial_x'], @properties['initial_y'])
    @whole_path.subpaths.last.directions << Savage::Directions::MoveTo.new(@properties['initial_x'], @properties['initial_y'])
    @whole_path.calculate_start_points!(@properties['initial_x'], @properties['initial_y'])
    @whole_path.calculate_angles!

  end

  def save(file_name, path)
    dimensions = calculate_dimensions(path)

    output_file = SVG.new(dimensions[0]+10, dimensions[1]+10)
    output_file.marker('arrow-start', 8, 8, '<polyline points="0,0 8,4 0,8 2,4 0,0" stroke-width="1" stroke="darkred" fill="red"/>', '-2%', 4)
    output_file.marker('arrow-end', 8, 8, '<polyline points="0,0 8,4 0,8 2,4 0,0" stroke-width="1" stroke="darkred" fill="red"/>', '2%', 4)
    output_file.style('g.stroke path:hover {stroke-width: 9;}g.move_to path:hover{stroke-width: 4;}')

    path_group = output_file.g

    path.subpaths.each_with_index do |subpath, i|
      if subpath.directions.first.kind_of? Savage::Directions::MoveTo
        output_file.svg << path_group

        move_to_subpath = Savage::SubPath.new
        position = path.subpaths[i-1].directions.last.target
        target = subpath.directions.first.target
        move_to_subpath.directions = [Savage::Directions::MoveTo.new(position.x, position.y), Savage::Directions::LineTo.new(target.x, target.y)]
        output_file.svg << output_file.g('red', 2, 'none', 'move_to', 'url(#arrow-start)', 'url(#arrow-end)') << output_file.path(move_to_subpath.to_command, "path_#{i}")

        path_group = output_file.g('black', 3)
      else
        point = path.subpaths[i-1].directions.last.target
        subpath.directions.insert(0, Savage::Directions::MoveTo.new(point.x, point.y))
        path_group << output_file.path(subpath.to_command, "path_#{i}")
      end


    end
    # g00 = @tpath.length[:length_g00]
    begin
      output_file.svg << output_file.text("Холостой ход: #{@properties[:g00]}mm, Рисование: #{@properties[:g01]}mm", 15, 15)
    rescue => e
      p "failed #{file_name}"
    end
    output_file.save(file_name)
    print "Saved to #{file_name}\n"
  end

  private
  def absolute!
    @paths.each(&:absolute!)
  end

  def calculate_dimensions(path)
    height = width = 0
    path.directions.each do |direction|
      width = direction.target.x if direction.target.x > width
      height = direction.target.y if direction.target.y > height
    end
    [width, height]
  end

  def find_first_point(subpath)
    start_point = nil
    subpath.directions.each do |direction|
      return start_point unless %w[M m].include? direction.command_code
      start_point = direction.target
    end
  end
end
