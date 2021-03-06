require_relative 'svg/svg'
require 'yaml'
require 'pp'

def find_width(paths)
  w = calculate_dimensions(paths)
  (w[2]-w[0])
end

def save_csv(file_name, paths)
  File.open(file_name, 'w') do |f|
    paths.each do |path|
      directions = []
      directions << [-1, -1]
      path.each do |subpath|
        directions += subpath.directions.map(&:finish).map(&:to_a)
      end
      directions << [-2, -2]
      directions.first << directions.size - 2
      directions.each do |d|
        if d.size == 3
          f.puts "#{d[0]},#{d[1]}, #{d[2]}"
        else
          f.puts "#{d[0]},#{d[1]}"
        end
      end
    end
  end
end

def save_scad(file_name, paths, dimensions, w)
  File.open(file_name, 'w') do |f|
    paths.each do |path|
      f.write 'linear_extrude(height = 1, max_y=2) '
      f.write 'polygon ( points='
      directions = []
      path.each do |subpath|
        directions += subpath.directions.map(&:finish).map(&:to_a)
      end
      f.write directions

      f.write ', paths = '
      path_points = []
      p = 0
      path.each do |subpath|
        size = subpath.directions.size
        path_points << Array.new(size).fill {|i| p + i}
        p += size
      end
      f.write path_points
      f.puts ');'
    end

    max_x = dimensions[2]
    min_x = dimensions[0]
    min_y = dimensions[1]

    f.write 'linear_extrude(height = 1, max_y=2) '
    f.write 'polygon ( points='
    f.write "[[#{min_x}, #{min_y+1}],[#{w/2-0.5},#{min_y+1}],[#{w/2-0.5}, #{min_y-1}],[#{w/2+0.5}, #{min_y-1}],[#{w/2+0.5}, #{min_y+1}],[#{max_x}, #{min_y+1}],[#{max_x}, #{min_y-4}],[#{min_x}, #{min_y-4}]]"
    f.puts ');'
  end
end

def calculate_dimensions(paths)
  max_x = -Float::INFINITY
  max_y = -Float::INFINITY

  min_x = Float::INFINITY
  min_y = Float::INFINITY

  paths.each do |path|
    path.each do |subpath|
      min_x = subpath.dimensions[0] if subpath.dimensions[0] < min_x
      min_y = subpath.dimensions[1] if subpath.dimensions[1] < min_y
      max_x = subpath.dimensions[2] if subpath.dimensions[2] > max_x
      max_y = subpath.dimensions[3] if subpath.dimensions[3] > max_y
    end
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
        path.each_with_index do |subpath, j|
          xml.g(class: 'stroke', stroke: 'black', 'stroke-width' => 1, fill: 'none', 'marker-start' => 'none', 'marker-end' => 'none') {
            xml.path(d: subpath.d, id: "path_#{i*j+j}")
          }
        end
      end
    }
  end

  File.open(file_name, 'w') {|f| f.write builder.to_xml}
  print "Saved to #{file_name}\n"
end


Dir.mkdir('result') unless Dir.exists?('result')
# file_name = 'images/hackerspace.svg'
file_name = 'images/shadow_sketch.svg'
# file_name = 'images/rectangle.svg'


svg = SVG.new file_name
properties = File.open('properties.yml') {|yf| YAML::load(yf)}

size = properties['max_segment_length']
svg.paths.each do |path|
  subpaths = []
  path.reject{|subpath| subpath.fill.nil?}.each do |subpath|
    splitted_path = subpath.split(size)
    splitted_path.d
    subpaths << splitted_path
  end
  svg.splitted_paths << subpaths unless subpaths.empty?
end

save('splitted.svg', svg.splitted_paths)

shadow_paths = []

lx = properties['light_x']
ly = -properties['light_y']
lz = properties['light_z']
w = find_width(svg.splitted_paths)

svg.splitted_paths.each {|path| path.each(&:organize!)}

svg.splitted_paths.each do |path|
  subpaths = []
  path.each do |subpath|
    spath = Path.new
    spath.fill = subpath.fill
    spath.stroke = subpath.stroke
    subpath.directions.each do |direction|
      sx = direction.finish.x
      sy = direction.finish.y
      x = sx - sy * (lx - sx) / (ly - sy)
      z = (lx - sx).zero? ? lz * sy / (sy - ly) : (x - sx) * lz / (lx - sx)
      spath.directions << Direction.new(direction.command_code, [x.round(2), z.round(2)])
    end
    spath.d
    subpaths << spath
  end
  shadow_paths << subpaths
end

shadow_paths.each {|path| path.each(&:organize!)}

save('shadow.svg', shadow_paths)
save_scad(
    "#{file_name.gsub('.svg', '')
           .gsub('images/', '')}_#{lx.to_i}_#{ly.to_i}_#{lz.to_i}.scad",
    shadow_paths,
    calculate_dimensions(shadow_paths), w
)

save_csv(file_name.gsub('.svg', '.csv').gsub('images/',''), shadow_paths)