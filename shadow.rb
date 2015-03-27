require_relative 'svg/svg'
require 'yaml'
require 'pp'

def find_width(paths)
  w = calculate_dimensions(paths)
  (w[2]-w[0])
end

def save_scad(file_name, points, dimensions=[])
  File.open(file_name, 'w') do |f|
    f.write 'linear_extrude(height = 1, max_y=2) '
    f.write 'polygon ( points='
    f.write points.map { |p| [p.x, p.y] }
    f.puts');'

    max_x = dimensions[2]
    min_x = dimensions[0]
    min_y = dimensions[1]

    f.write 'linear_extrude(height = 1, max_y=2) '
    f.write 'polygon ( points='
    f.write "[[#{min_x}, #{min_y}],[#{max_x}, #{min_y}],[#{max_x}, #{min_y-5}],[#{min_x}, #{min_y-5}]]"
    f.puts');'
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
      xml.style 'g.stroke path:hover {stroke-width: 2;}'
      xml.style 'g.move_to path:hover{stroke-width: 2;}'

      paths.each_with_index do |path, i|
        xml.g(class: 'stroke', stroke: 'black', 'stroke-width' => 1, fill: 'none', 'marker-start' => 'none', 'marker-end' => 'none') {
          xml.path(d: path.d, id: "path_#{i}")
        }
      end
    }
  end

  File.open(file_name, 'w') { |f| f.write builder.to_xml }
  print "Saved to #{file_name}\n"
end


Dir.mkdir('result') unless Dir.exists?('result')
file_name = 'images/hackerspace.svg'
# file_name = 'images/tower.svg'
# file_name = 'images/circle.svg'


svg = SVG.new file_name
properties = File.open('properties.yml') { |yf| YAML::load(yf) }

size = properties['max_segment_length']
svg.paths.each { |path| svg.splitted_paths << path.split(size) }

save('splitted.svg', svg.splitted_paths)

shadow_paths = []

d = properties['d']
w = find_width(svg.splitted_paths)
h = properties['h']

svg.splitted_paths.each(&:organize!)

svg.splitted_paths.each do |path|
  spath = Path.new
  path.directions.each do |direction|
    x0 = direction.finish.x
    y0 = direction.finish.y
    x = (d * (x0-w/2)/(d+y0) + w/2).round(2)
    y = (h - d * h / (d+y0)).round(2)
    spath.directions << Direction.new(direction.command_code, [x, y])
  end
  shadow_paths << spath
end

shadow_paths.each(&:organize!)

save('shadow.svg', shadow_paths)
save_scad('shadow.scad', shadow_paths.map { |p| p.directions.map(&:finish) }.flatten, calculate_dimensions(shadow_paths))