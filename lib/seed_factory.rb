# Retuns layer as string and the generated ID
def layer_builder(layer_name)
	layer_hash = {}
	layer_hash['name'] = layer_name || "No Layer Name"
	layer_hash['id'] = rand(1..100000)
	layer_seed = "Layer.seed(:id,\n" + "\t#{layer_hash.to_json}" + "\n)\n"
	return [layer_seed, layer_hash['id']]
end

# Simple hash creator
def feature_builder(layer_id, fillColor, zoom, projection)
	feature_hash = {}
	feature_hash['id'] = rand(1..100000)
	feature_hash['layer_id'] = layer_id
	feature_hash['fill_color'] = fillColor
	feature_hash['zoom_level'] = zoom
	feature_hash['geo_data'] = projection
	return feature_hash
end