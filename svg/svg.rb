require 'nokogiri'
require_relative 'path/path'

class SVG
  attr_accessor :paths
  attr_reader :width, :height

  def initialize(file_name)
    read_svg(file_name)
  end

  private
  def read_svg(file_name)
    @paths = []
    elements = []
    svg = Nokogiri::XML open file_name
    svg.traverse do |e|
      elements.push e if e.element?
    end
    elements.map do |e|
      @paths.push e.attribute_nodes.select { |a| a.name == 'd' }
    end
    @paths.flatten!.map!(&:value).map! { |path| Path.parse path }
    @paths.flatten!
    @width = svg.at_css('svg')[:width].to_f
    @height = svg.at_css('svg')[:height].to_f
  end

  def split!(size)
    @splitted_path = []
    @paths.directions.each_with_index do |direction, i|
      if %w[S s T t].include? direction.command_code # smooth curves need second control point of previous curve
        new_directions = direction.split size, @paths.directions[i-1].control_2
      else
        new_directions = direction.split size
      end

      path = Path.new
      path.directions = new_directions
      @splitted_path << path

    end

    # @splitted_path.calculate_start_points!(@properties['initial_x'], @properties['initial_y'])
    # @splitted_path.calculate_angles!
  end

end