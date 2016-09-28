#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'json'
require 'trollop'
require 'rgeo/geo_json'
require 'rgeo'
require 'seed_factory'
require 'projection_factory'
require 'pry'


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
feature_seed = "LayerFeature.seed(:id,\n"
feature_array = []


# Setup RGeo factory for handling geographic data
# Uses projection for calculations
# Converts area/distance calculations to meters (75% sure)
factory = RGeo::Geographic.simple_mercator_factory(:srid => 4326)


# Begin iterating through data
map_data.each.with_index(1) do |item, index|

	# Good for monitoring progress
	puts "Starting item ##{index}! Left to go: #{(map_data.length - index)}"

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

		# Begin simplification
		projection = ProjectionFactory.new(geo_data_projection, factory)

		# Filter out holes that you can't see zoomed out
		projection.hole_deleter(zoom_params['minimum_hole_size'])

		# Simplify to a percentage of the original
		simplfied_poly = \
			projection.polygon_simplifier(zoom_params['simplification'])

		# Adding to array
		feature_array << feature_builder(layer_id, 
				color_hash[item['properties']['LIQ']], 
				zoom_level, simplfied_poly)

		end
	end
end

feature_seed += "\t" + "#{feature_array.to_json}" + "\n)\n"

output.write(feature_seed) unless output.nil?

output.close

puts "\a"

