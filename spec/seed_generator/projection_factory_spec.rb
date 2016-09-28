require 'spec_helper'
require 'projection_factory'

factory = RGeo::Cartesian.factory

outer_point_1 = factory.point(10,10)
outer_point_2 = factory.point(15,0)
outer_point_3 = factory.point(10,-10)
outer_point_4 = factory.point(0,-15)
outer_point_5 = factory.point(-10,-10)
outer_point_6 = factory.point(-15,-0)
outer_point_7 = factory.point(-10,10)
outer_point_8 = factory.point(0,15)
outer_string = factory.linear_ring([outer_point_1, outer_point_2, 
	outer_point_3, outer_point_4, outer_point_5, outer_point_6,
	outer_point_7, outer_point_8])
outer_poly = factory.polygon(outer_string)

small_inner_point_1 = factory.point(2,2)
small_inner_point_2 = factory.point(2,1)
small_inner_point_3 = factory.point(1,1)
small_inner_point_4 = factory.point(1,2)
small_inner_string = factory.linear_ring([small_inner_point_1,
	small_inner_point_2, small_inner_point_3, small_inner_point_4])
small_inner_poly = factory.polygon(small_inner_string)

large_inner_point_1 = factory.point(-5,5)
large_inner_point_2 = factory.point(-5,0)
large_inner_point_3 = factory.point(-9,0)
large_inner_point_4 = factory.point(-9,5)
large_inner_string = factory.linear_ring([large_inner_point_1,
	large_inner_point_2, large_inner_point_3, large_inner_point_4])
large_inner_poly = factory.polygon(large_inner_string)

poly = factory.polygon(outer_string, [small_inner_string, 
	large_inner_string])

test_geo = factory.collection([poly])


puts outer_poly.simplify(100)






# for item in test_geo[0].interior_rings
# 	puts factory.polygon(item).area
# end



describe ProjectionFactory do

  describe "small hole remover" do

	let(:projection) { ProjectionFactory.new(test_geo) }

	it "removes the smaller hole" do

		hole_filtered_poly = projection.hole_deleter(5, factory)

		expect(hole_filtered_poly[0].num_interior_rings).to eq(1)

	end

  end

end



