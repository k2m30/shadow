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
    @paths.each {|path| @splitted_paths << path.split(size)}
  end

  private
  def read_svg(file_name)
    @paths = []
    svg = Nokogiri::XML open file_name
    svg.traverse do |e|
      @paths.push e if e.element? and e.name == 'path'
    end
    @paths.map! { |path| Path.parse path }
    @width = svg.at_css('svg')[:width].to_f
    @height = svg.at_css('svg')[:height].to_f
  end
end