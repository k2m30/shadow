require_relative 'svg/svg'
require 'yaml'
require 'pp'

ShadowPoint = Struct.new :x, :y, :z

def find_center(paths)
  w = calculate_dimensions(paths)
  w[2]-w[0]
end

def save_scad(file_name, points)
  File.open(file_name, 'w') do |f|
    f.write 'linear_extrude(max_y=2) '
    f.write 'polygon ( points='
    f.write points.map{|p| [p.x, p.z]}
    f.write ');'
  end
end

def calculate_dimensions(paths)
  max_x = -Float::INFINITY
  max_y = -Float::INFINITY

  min_x = Float::INFINITY
  min_y = Float::INFINITY

  paths.each do |path|
    min_x = path.dimensions[0] if path.dimensions[0] < min_x
    min_y = path.dimensions[1] if path.dimensions[1] < min_y
    max_x = path.dimensions[2] if path.dimensions[2] > max_x
    max_y = path.dimensions[3] if path.dimensions[3] > max_y
  end
  [min_x, min_y, max_x, max_y]
end


def save(file_name, paths)
  dimensions = calculate_dimensions(paths)

  builder = Nokogiri::XML::Builder.new do |xml|
    xml.doc.create_internal_subset(
        'svg',
        '-//W3C//DTD SVG 1.1//EN',
        'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'
    )
    xml.svg(version: '1.1', xmlns: 'http://www.w3.org/2000/svg', 'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
            x: 0, y: 0, width: dimensions[2], height: dimensions[3], viewBox: "0, 0, #{dimensions[2]}, #{dimensions[3]}") {
      xml.marker(id: 'arrow-start', markerWidth: 8, markerHeight: 8, refX: '-2%', refY: 4, markerUnits: 'userSpaceOnUse', orient: 'auto') {
        xml.polyline(points: '0,0 8,4 0,8 2,4 0,0', 'stroke-width' => 1, stroke: 'darkred', fill: 'red')
      }
      xml.marker(id: 'arrow-end', markerWidth: 8, markerHeight: 8, refX: '2%', refY: 4, markerUnits: 'userSpaceOnUse', orient: 'auto') {
        xml.polyline(points: '0,0 8,4 0,8 2,4 0,0', 'stroke-width' => 1, stroke: 'darkred', fill: 'red')
      }
      xml.style 'g.stroke path:hover {stroke-width: 9;}'
      xml.style 'g.move_to path:hover{stroke-width: 4;}'

      paths.each_with_index do |path, i|
        xml.g(class: 'stroke', stroke: 'black', 'stroke-width' => 3, fill: 'none', 'marker-start' => 'none', 'marker-end' => 'none') {
          xml.path(d: path.d, id: "path_#{i}")
        }
      end
    }
  end
  puts builder.to_xml

  File.open(file_name, 'w') { |f| f.write builder.to_xml }
  print "Saved to #{file_name}\n"
end


Dir.mkdir('result') unless Dir.exists?('result')
# file_name = '../genko/images/hare.svg'
file_name = 'images/lines.svg'
# file_name = 'images/circle.svg'


svg = SVG.new file_name
properties = File.open('properties.yml') { |yf| YAML::load(yf) }

spaths = []
size = properties['max_segment_length']
svg.paths.each do |path|
  spaths << path.split(size)
end

save('splitted.svg', spaths)

shadow_paths = spaths.clone

d = properties['d']
w = find_center(shadow_paths)
h = properties['h']

p w

shadow_paths.each do |path|
  path.directions.each do |direction|
    unless direction.start.nil?
      x0 = direction.start.x
      y0 = direction.start.y
      direction.start.x = d * (x0-w/2)/(d+y0) + w/2
      # y = d
      direction.start.y = h - d * h / (d+y0)
    end
    unless direction.finish.nil?
      x0 = direction.finish.x
      y0 = direction.finish.y
      direction.finish.x = d * (x0-w/2)/(d+y0) + w/2
      # y = d
      direction.finish.y = h - d * h / (d+y0)
    end
  end
end

save('shadow.svg', shadow_paths)
save_scad('shadow.scad', shadow_paths)

# @properties = File.open('properties.yml') { |yf| YAML::load(yf) }
#
# svg = SVG.new 'images/hare.svg'
#
# svg.paths.each do |path|
#   path.directions.each do |direction|
#     p [direction.command_code, direction.start]
#   end
#   p '-----'
# end
#
# spaths = []
# size = @properties['max_segment_length']
# svg.paths.each do |path|
#   spaths << path.split(size)
# end
#
# save('splitted.svg', spaths)