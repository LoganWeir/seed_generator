#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'json'
require 'trollop'
require 'rgeo/geo_json'
require 'rgeo'
# For pretty printing, if needed
require 'pry'

require 'seed_factory'
require 'projection_factory'



# Set options outside of ARGV
opts = Trollop::options do
  opt :output_name, "Output Name", default: nil, 
  	short: 'o', type: String
  opt :layer_name, "Layer Name", default: nil, short: 'n', type: String
  opt :layer_id, "Layer ID", default: nil, short: 'i', type: Integer
end


# Import all parameters for the generator
seed_parameters = JSON.parse(File.read('seed_parameters.json'))


map_data = []
# Allows for multiple files to be processed
ARGV.each do | item |
	raw_data = JSON.parse(File.read(item))
	for feature in raw_data['features']
		# Set filter target
		filter_target = feature['properties']['LIQ']
		# Separate with ternary operator
		seed_parameters['filter_parameters'].include?(filter_target) ? \
			next : map_data << feature
	end
end


# Only produce output file if asked for
if opts[:output_name].nil?
	puts "No Seed Output"
	output = nil
else
	path_file = 'output/' + opts[:output_name]
	output = open(path_file, 'w')
end


# Allows for building two seed files for same layer
if opts[:layer_id] == nil
	layer = layer_builder(opts[:layer_name])
	layer_id = layer[1]
	# Write if outputting
	output.write(layer[0]) unless output.nil?
	puts ">>>>>\nLayer ID = #{layer_id}\n<<<<<"
else
	# Doesn't build layer seed, only feature
	layer_id = opts[:layer_id]
	puts ">>>>>\nUsing Layer ID #{opts[:layer_id]}\n<<<<<"
end


color_hash = seed_parameters['color_parameters']

zoom_hash = seed_parameters['zoom_parameters']


# Starting the Ruby file and output array
feature_seed = "LayerFeature.seed(:feature_id,\n"
feature_array = []

# Setup RGeo factory for handling geographic data
# Uses projection for calculations
# Converts area/distance calculations to meters (75% sure)
factory = RGeo::Geographic.simple_mercator_factory(:srid => 4326)

other_factory = RGeo::Geographic.spherical_factory(:srid => 4326)

test_array = []

single_broken = []

# Begin iterating through data
map_data.each.with_index(1) do |item, index|

	# # Good for monitoring progress
	# puts "Starting item ##{index}! Left to go: #{(map_data.length - index)}"

	# 7926

	# if item['properties']['QUAT_ID'] == 7926 || item['properties']['QUAT_ID'] == 7976

	if item['properties']['QUAT_ID'] == 7926

		# Convert data into RGeo, then proper factory
		rgeo_hash = RGeo::GeoJSON.decode(item['geometry'])
		geo_data_projection = factory.collection([rgeo_hash])

		zoom_hash.each do |zoom_level, zoom_params|

		 	# Skip if included in feature skip array
			next if zoom_params['feature_skip'].include?\
				(item['properties']['LIQ'])

			# Filters out polygons based on size and fill
			next if zoom_test(geo_data_projection[0], 
				zoom_params['size_fill_limits']) == false

			projection = ProjectionFactory.new(geo_data_projection, factory)

			projection.hole_deleter(zoom_params['minimum_hole_size'])

			simplfied_poly = \
				projection.polygon_simplifier(zoom_params['simplification'])

			# # Adding to array
			# feature_array << feature_builder(layer_id, 
			# 	color_hash[item['properties']['LIQ']], 
			# 	zoom_level, simplfied_poly)

			# test_array << simplfied_poly

			max_exterior_points = 100

			chop_test = polygon_divider(simplfied_poly, max_exterior_points, factory)

			if chop_test[0] == true
				
				for polygon in chop_test[1]

					# feature_array << feature_builder(layer_id, 
					# 	color_hash[item['properties']['LIQ']], 
					# 	zoom_level, polygon)

					# if polygon.intersects?(factory.point(-122.397822, 37.799161))

					# Smaller dividing, point at exploritorium
					if polygon.intersects?(factory.point(-122.398945, 37.801167))

						# feature_array << feature_builder(layer_id, 
						# 	color_hash[item['properties']['LIQ']], 
						# 	zoom_level, polygon)

						single_broken << polygon


					end

					# 	p "original size: #{total_point_count(polygon)}"

					# 	new_simple = polygon[0].simplify(0)

					# 	p "new size: #{total_point_count(factory.collection([new_simple]))}"

					# 	feature_array << feature_builder(layer_id, 
					# 		color_hash[item['properties']['LIQ']], 
					# 		zoom_level, factory.collection([new_simple]))

					# else

					# 	feature_array << feature_builder(layer_id, 
					# 		color_hash[item['properties']['LIQ']], 
					# 		zoom_level, polygon)

					# end

				end

			# else

			# 	# Adding to array
			# 	feature_array << feature_builder(layer_id, 
			# 		color_hash[item['properties']['LIQ']], 
			# 		zoom_level, simplfied_poly)

			end

		end
	end
end



# Comparing Raw Polygons, one bad one good
# soma_poly = test_array[0]
# first = soma_poly[0].exterior_ring.coordinates[0]
# last = soma_poly[0].exterior_ring.coordinates[-1]
# p first == last
# richmond_poly = test_array[1]
# p richmond_poly[0].num_interior_rings


# Analyzing tiny, broken chunk
# p total_point_count(single_broken[0])

# p single_broken[0]

new_broken = polygon_divider(single_broken[0], 30, factory)


# 37.801874, -122.398307

geometries = []

for item in new_broken[1]

# RGeo::Geographic.spherical_factory(srid: 4326)

	# puts item.cast(:factory = )

	p RGeo::Feature.cast(item, :factory => other_factory)

	# if item.intersects?(factory.point(-122.398307, 37.801874))

	# 	# geometries << item[0]

	# 	# unique_len = item[0].exterior_ring.coordinates.uniq.length

	# 	# normal_len = item[0].exterior_ring.coordinates.length

	# 	p item[0].inspect

	# 	# puts normal_len - unique_len

	# 	# bad_poly_ring = item[0].exterior_ring.coordinates

	# 	# # p bad_poly_ring.length

	# 	# bad_poly_ring.delete_at(1)

	# 	# # p bad_poly_ring.length


	# 	# ring = factory.linear_ring(bad_poly_ring)

	# 	# new_poly = factory.polygon(ring)

	# 	# puts new_poly

	# 	# feature_array << feature_builder(layer_id, 
	# 	# 	"#a50f15", 
	# 	# 	"13", item)

	# 	# for coord_pair in item[0].exterior_ring.coordinates

	# 	# 	point = factory.point(coord_pair[0], coord_pair[1])

	# 	# 	geometries << point
	# 	# 	# p coord_pair[1].to_s.length

	# 	# end

	# 	# pp(RGeo::GeoJSON.encode(item).to_json)

	# end

end

# new_collection = factory.collection(geometries)

# puts RGeo::GeoJSON.encode(new_collection).to_json


# feature_array << feature_builder(layer_id, 
# 	"#a50f15", 
# 	"13", item)


feature_seed += "\t" + "#{feature_array.to_json}" + "\n)\n"

output.write(feature_seed) unless output.nil?

output.close unless output.nil?

puts "\a"

