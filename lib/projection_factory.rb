require 'rgeo/geo_json'
require 'rgeo'



class ProjectionFactory

	def initialize(projection, factory)
		@projection = projection
		@factory = factory
	end


	def hole_deleter(minimum_hole_size)
		# If holes
		if @projection[0].num_interior_rings > 0
			new_inner_array = []
			# For each hole
			for inner_ring in @projection[0].interior_rings do
				# Test size
				if @factory.polygon(inner_ring).area > minimum_hole_size
					# If big enough, add to array
					new_inner_array << inner_ring
				end
			end

			if new_inner_array.length > 0
				# If any made it, build new polygon
				new_projection = @factory.polygon(@projection[0].exterior_ring, new_inner_array)
			else
				# Else, new polygon with no holes
				new_projection = @factory.polygon(@projection[0].exterior_ring)				
			end
			@projection = @factory.collection([new_projection])
		end
	end


	def polygon_simplifier(point_reduction_ratio)

		polygon = @projection[0]

		max_points = polygon.exterior_ring.num_points * point_reduction_ratio
		
		simplfication = 0

		# Breaks if exterior points are lowered enough
		while polygon.exterior_ring.num_points > max_points
	
			simplfication += 1

			new_simple_projection = polygon.simplify(simplfication)

			# Over-simplification can delete polygons
			if new_simple_projection == nil
				break
			elsif new_simple_projection.is_empty?
				break 
			# Over-simplification can turn the projection into a multi-polygon
			elsif new_simple_projection.geometry_type.type_name == "MultiPolygon"
				break 					
			else
				polygon = new_simple_projection
			end
		end

		final_projection = @factory.collection([polygon])

	end

end

		

# Test polygon for size and fill at 3 levels
def zoom_test(polygon, size_fill_hash = {})
	test = 0
	polygon_fill = polygon.area/polygon.envelope.area
	for key, value in size_fill_hash
		if polygon.area > value && polygon_fill > key.to_f
			test += 1
		end
	end
	test > 0 ? true : false
end




def quarter_chop(polygon, factory)

	envelope = polygon.envelope

	env_center_coords = envelope.centroid.coordinates

	center_lon = env_center_coords[0]
	center_lat = env_center_coords[1]

	sub_boxes = []

	for corner in envelope.coordinates[0][0..3]

		corner_lon = corner[0]
		corner_lat = corner[1]

		point_1 = factory.point(corner_lon, center_lat)
		point_2 = factory.point(center_lon, center_lat)
		point_3 = factory.point(center_lon, corner_lat)
		point_4 = factory.point(corner_lon, corner_lat)

		ring = factory.linear_ring([point_1, point_2, point_3, point_4])
		box = factory.polygon(ring)

		sub_boxes << box

	end

	sub_boxes

end


def polygon_length_checker(polygon_collection_array, max_exterior_points)

	test = 0

	for polygon_collection in polygon_collection_array

		if polygon_collection[0].exterior_ring.num_points > max_exterior_points

			test += 1

		end

	end

	test > 0 ? true : false

end




def polygon_divider(poly_collection, max_exterior_points, factory)

	if poly_collection[0].exterior_ring.num_points > max_exterior_points

		divided_polys = []

		# First pass at chopping
		poly_chopper(poly_collection[0], divided_polys, factory)

		length_test = polygon_length_checker(divided_polys, max_exterior_points)

		attempts = 0

		while length_test == true

			# # Used for measuring attempts
			# attempts += 1
			# puts "Attempt ##{attempts}"

			new_array = []

			for polygon in divided_polys

				if polygon[0].exterior_ring.num_points > max_exterior_points

					poly_chopper(polygon[0], new_array, factory)

				else

					new_array << polygon

				end
			end

			divided_polys = new_array

			length_test = polygon_length_checker(divided_polys, max_exterior_points)

		end
		
		return [true, divided_polys]

	else

		return [false]

	end
	
end



def poly_chopper(polygon, output_array, factory)

	sub_boxes = quarter_chop(polygon, factory)

	for box in sub_boxes

		poly_chop = box.intersection(polygon)

		geo_type = poly_chop.geometry_type.type_name

		if geo_type == "Polygon"
	
			output_array << factory.collection([poly_chop])

		elsif geo_type == "MultiPolygon"

			for single_poly in poly_chop

				output_array << factory.collection([single_poly])

			end
		end
	end
end



def total_point_count(poly_collection)

	total_count = 0

	total_count += poly_collection[0].exterior_ring.num_points

	if poly_collection[0].num_interior_rings > 0

		for inner_ring in poly_collection[0].interior_rings do 

			total_count += inner_ring.num_points

		end

	end

	total_count

end

