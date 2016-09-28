require 'spec_helper'
require 'seed_factory'


RSpec.describe "#layer_builder" do

  test_layer = layer_builder(nil)

  it "generates a string as its first element" do

    expect(test_layer[0].is_a?(String)).to eq(true)

  end

  it "generates an integer as its second" do

    expect(test_layer[1].is_a?(Integer)).to eq(true)

  end

  it "accepts layer_name if present" do

    test_layer = layer_builder("kangaroo")

    expect(test_layer[0]).to include("kangaroo")

  end

end










#   describe EventFactory do

#     let(:types) {%i(water temp sound motion)}
#     let(:now) { DateTime.now }
#     let(:event_1) {Timecop.freeze(now) { EventFactory.event(SecureRandom.uuid, types.sample) }}
#     let(:event_2) {Timecop.freeze(now) { EventFactory.event(SecureRandom.uuid, types.sample) }}

#     describe "initialize" do
#       it "generates a unique id" do
#         expect(event_1[:id]).to_not eq(event_2[:id])
#       end

#       it "generates a unix timestamp equal to now" do
#         expect(event_1[:utcTimestamp]).to eq(now.strftime('%Q'))
#       end
#     end
# end