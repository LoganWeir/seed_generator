require 'rgeo/geo_json'
require 'rgeo'

# Test polygon for size and fill at 3 levels
def zoom_test(polygon, size_fill_hash = {})
	test = 0
	polygon_fill = polygon.area/polygon.envelope.area
	for key, value in size_fill_hash
		if polygon.area > key.to_f && polygon_fill > value
			test += 1
		end
	end
	test > 0 ? true : false
end



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
