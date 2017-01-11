# Retuns layer as string and the generated ID
def layer_builder(layer_name)
	layer_hash = {}
	layer_hash['name'] = layer_name || "no_layer_name"
	layer_hash['id'] = rand(1..100000)
	# layer_seed = "Layer.seed(:id,\n" + "\t#{layer_hash.to_json}" + "\n)\n"
	return [layer_hash, layer_hash['id']]
end

# Simple hash creator
def feature_builder(poly_params, projection)
	feature_hash = {}
	alpha_num = (('a'..'z').to_a + (0..9).to_a)
	feature_hash['feature_id'] = \
		(0..35).map { alpha_num[rand(alpha_num.length)] }.join
	feature_hash['layer_id'] = poly_params['id']
	feature_hash['fill_color'] = poly_params['color']
	feature_hash['zoom_level'] = poly_params['zoom']
	feature_hash['geo_data'] = projection
	feature_hash['popup_title'] = poly_params['title']
	feature_hash['popup_description'] = poly_params['description']
	return feature_hash
end