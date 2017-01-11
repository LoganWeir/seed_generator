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

# Final output
final_output = {}

# Only produce output file if asked for
if opts[:output_name].nil?
	puts "No Seed Output"
	output = nil
else
	# Adding master hash for json output
	path_file = 'output/' + opts[:output_name]	
	output = open(path_file, 'w')
end


# Allows for building two seed files for same layer
if opts[:layer_id] == nil
	layer = layer_builder(opts[:layer_name])
	layer_id = layer[1]
	# Write if outputting MODIFIED TO JSON
	final_output['layer_data'] = layer[0]
	# output.write(layer[0]) unless output.nil?
	puts ">>>>>\nLayer ID = #{layer_id}\n<<<<<"
else
	# Doesn't build layer seed, only feature
	layer_id = opts[:layer_id]
	puts ">>>>>\nUsing Layer ID #{opts[:layer_id]}\n<<<<<"
end


color_hash = seed_parameters['color_parameters']
popup_hash = seed_parameters['popup_parameters']

zoom_hash = seed_parameters['zoom_parameters']


# Starting the Ruby file and output array
# Don't need seed_file format when outputting json
# feature_seed = "LayerFeature.seed(:feature_id,\n"
feature_array = []

# Setup RGeo factory for handling geographic data
# Uses projection for calculations
# Converts area/distance calculations to meters (75% sure)
factory = RGeo::Geographic.simple_mercator_factory(:srid => 4326)


test_data = map_data[0..100]


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

		# Create poly properties hash
		poly_params = {}
		poly_params['id'] = layer_id
		poly_params['title'] = popup_hash['title']
		poly_params['description'] = popup_hash[item['properties']['LIQ']]
		poly_params['color'] = color_hash[item['properties']['LIQ']]
		poly_params['zoom'] = zoom_level


		projection = ProjectionFactory.new(geo_data_projection, factory)

		projection.hole_deleter(zoom_params['minimum_hole_size'])


		simplfied_poly = \
			projection.polygon_simplifier(zoom_params['simplification'])

		if zoom_params['poly_divide_limit']

			chop_test = polygon_divider(simplfied_poly, 
				zoom_params['poly_divide_limit'], factory)

			if chop_test[0] == true
				
				for polygon in chop_test[1]

					# Adding to array
					feature_array << feature_builder(poly_params, 
						factory.collection([polygon]))

				end

			else

				# Adding to array
				feature_array << feature_builder(poly_params,
					simplfied_poly)

			end

		else

			# Adding to array
			feature_array << feature_builder(poly_params, 
				simplfied_poly)

		end
	end
end


# feature_seed += "\t" + "#{feature_array.to_json}" + "\n)\n"

puts "Total feature count: #{feature_array.length}"

final_output['feature_data'] = feature_array

output.write(final_output.to_json) unless output.nil?

output.close unless output.nil?

puts "\a"

