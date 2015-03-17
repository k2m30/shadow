require_relative 'svg/svg'
require 'yaml'
require 'pp'

ShadowPoint = Struct.new :x, :y, :z

# def find_center(points)
#   max_x = points.first.x
#   min_x = points.first.x
#   points.each do |point|
#
#     max_x = point.x if max_x < point.x && point.x > 0
#     min_x = point.x if min_x > point.x && point.x > 0
#   end
#   max_x - min_x
# end
#
# def save_scad(file_name, points)
#   File.open(file_name, 'w') do |f|
#     f.write 'linear_extrude(height=2) '
#     f.write 'polygon ( points='
#     f.write points.map{|p| [p.x, p.z]}
#     f.write ');'
#   end
# end
#
# def calculate_dimensions(path)
#   height = width = 0
#   path.directions.each do |direction|
#     next if direction.kind_of? Savage::Directions::ClosePath
#     width = direction.target.x if direction.target.x > width
#     height = direction.target.y if direction.target.y > height
#   end
#   [width, height]
# end
#
# def save(file_name, path)
#   dimensions = calculate_dimensions(path)
#
#   output_file = SVG.new(dimensions[0]+10, dimensions[1]+10)
#   path.subpaths.each_with_index do |subpath, i|
#       output_file.svg << output_file.path(subpath.to_command, "path_#{i}")
#   end
#   output_file.save(file_name)
#   print "Saved to #{file_name}\n"
# end
#
#
#
# Dir.mkdir('result') unless Dir.exists?('result')
# # file_name = '../genko/images/hare.svg'
# file_name = 'images/lines.svg'
# file_name = 'images/circle.svg'
#
#
# svg_file = SVGFile.new(file_name)
#
# svg_file.save('splitted.svg', svg_file.splitted_path)
#
# points = []
#
# svg_file.splitted_path.directions.each do |direction|
#   if direction.kind_of? Savage::Directions::LineTo
#     points << ShadowPoint.new(direction.position.x, direction.position.y, 0)
#   end
# end
# # points << ShadowPoint.new(svg_file.splitted_path.directions.last.target.x, svg_file.splitted_path.directions.last.target.y)
#
# zpoints = []
#
# properties = svg_file.properties
# d = properties['d']
# w = find_center(points)
# h = properties['h']
#
# p w
#
# points.each do |p|
#   x0 = p.x
#   y0 = p.y
#
#   x = d * (x0-w/2)/(d+y0) + w/2
#   y = d
#   z = h - d * h / (d+y0)
#
#   zpoints << ShadowPoint.new(x, y, z)
# end
#
# @shadow_path = Savage::Path.new
#
# s = Savage::SubPath.new
# s.directions << Savage::Directions::MoveTo.new(zpoints.first.x, zpoints.first.z)
#
#
# zpoints.each do |point|
#   s.directions << Savage::Directions::LineTo.new(point.x, point.z)
# end
#
# s.directions.pop
# s.directions << Savage::Directions::ClosePath.new
#
# @shadow_path.subpaths << s
#
# save('shadow.svg', @shadow_path)
#
# # zpoints.pop
# save_scad('shadow.scad', zpoints)

def calculate_dimensions(path)
  height = width = 0
  path.directions.each do |direction|
    next if direction.is_a? ClosePath
    width = direction.finish.x if direction.finish.x > width
    height = direction.finish.y if direction.finish.y > height
  end
  [width, height]
end


def save(file_name, paths)
  dimensions = calculate_dimensions(path)

  output_file = SVG.new(dimensions[0]+10, dimensions[1]+10)
  paths.each_with_index do |subpath, i|
      output_file.svg << output_file.paths(subpath.to_command, "path_#{i}")
  end
  output_file.save(file_name)
  print "Saved to #{file_name}\n"
end


@properties = File.open('properties.yml') { |yf| YAML::load(yf) }

svg = SVG.new 'images/hare.svg'

svg.paths.each do |path|
 path.directions.each do |direction|
   p [direction.command_code, direction.start]
 end
  p '-----'
end

spaths = []
size = @properties['max_segment_length']
svg.paths.each do |path|
  spaths << path.split(size)
end

save('splitted.svg',spaths)