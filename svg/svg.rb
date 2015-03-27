require 'nokogiri'
require_relative 'path/path'

class SVG
  attr_accessor :paths, :splitted_paths
  attr_reader :width, :height

  def initialize(file_name)
    @splitted_paths = []
    read_svg(file_name)
  end

  def split!(size)
    @paths.each { |path| @splitted_paths << path.split(size) }
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
    @paths.flatten!.map!(&:value).map! { |path| Path.parse path }.flatten!
    @width = svg.at_css('svg')[:width].to_f
    @height = svg.at_css('svg')[:height].to_f
  end
end