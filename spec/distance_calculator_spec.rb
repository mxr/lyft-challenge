require 'spec_helper'

require_relative '../detour'
require_relative '../dist_calc'
require_relative '../distance_calculator'

describe DistanceCalculator do

  let(:seattle)   { Coordinate.new(47.606209, -122.332071) }
  let(:sunnyvale) { Coordinate.new(37.368830, -122.03635) }
  let(:austin)    { Coordinate.new(30.267153, -97.743061) }
  let(:nyc)       { Coordinate.new(40.714353, -74.005973) }
  let(:moscow)    { Coordinate.new(55.755826, 37.6173) }

  let(:reachable)       { Detour.new(seattle, nyc) }
  let(:unreachable)     { Detour.new(seattle, moscow) }
  let(:invalid_detour)  { Detour.new(seattle, nil) }

  describe '.distance' do
    context 'when computing the distance' do
      it 'returns unreachable for no start' do
        expect(DistanceCalculator.distance(nil, seattle, reachable)).
          to eq(Float::INFINITY)
      end

      it 'returns unreachable for no terminus' do
        expect(DistanceCalculator.distance(seattle, nil, invalid_detour)).
          to eq(Float::INFINITY)
      end

      it 'returns 0 when the start and end are the same with no detour' do
        expect(DistanceCalculator.distance(seattle, seattle.clone)).
          to eq(0)
      end

      it 'returns 0 when the start, end, and detour are the same place' do
        start = nyc
        detour = Detour.new(start.clone, start.clone)
        terminus = start.clone
        expect(DistanceCalculator.distance(start, terminus, detour)).to eq(0)
      end

      it 'returns unreachable for unreachable endpoints' do
        expect(DistanceCalculator.distance(seattle, moscow)).
          to eq(Float::INFINITY)
      end

      it 'returns unreachable for an unreachable detour' do
        expect(DistanceCalculator.distance(seattle, nyc, unreachable)).
          to eq(Float::INFINITY)
      end

      it 'returns unreachable for an invalid detour' do
        expect(DistanceCalculator.distance(seattle, nyc, invalid_detour)).
          to eq(Float::INFINITY)
      end

      it 'returns a reasonable value for no detour' do
        expect(DistanceCalculator.distance(seattle, nyc)).
          to be > 0
      end

      it 'returns a reasonable value for valid detour' do
        expect(DistanceCalculator.distance(seattle, nyc, reachable)).
          to be > 0
      end
    end

    context 'when the API key is invalid' do
      before { allow(File).to receive(:read).and_return('foo') }

      it 'raises an exception' do
        expect(lambda { DistanceCalculator.distance(seattle, nyc, reachable) }).
          to raise_error(DistanceError)
      end
    end

    context 'when the server returns 404' do
      before do
        io = double('io')
        io.stub_chain(:status, :first).and_return('404')
        allow(DistanceCalculator).to receive(:open)
                                 .and_raise(OpenURI::HTTPError.new('', io))
      end

      it 'returns unreachable' do
        expect(DistanceCalculator.distance(nyc, nyc, unreachable)).
          to eq(Float::INFINITY)
      end
    end

    context 'when the server returns an unsupported error code' do
      before do
        io = double('io')
        io.stub_chain(:status, :first).and_return('403')
        allow(DistanceCalculator).to receive(:open)
                                 .and_raise(OpenURI::HTTPError.new('', io))
      end

      it 'raises an exception' do
        expect(lambda { DistanceCalculator.distance(seattle, nyc, reachable) }).
          to raise_error(DistanceError)
      end
    end

    context 'when the server returns a badly-formatted response' do
      before { DistanceCalculator.stub_chain(:open, :read).and_return('foo') }

      it 'raise an exception' do
        expect(lambda { DistanceCalculator.distance(seattle, nyc, reachable) }).
          to raise_error(DistanceError)
      end
    end

    context 'when the server returns an incomplete response' do
      before { DistanceCalculator.stub_chain(:open, :read).and_return('{}') }

      it 'raise an exception' do
        expect(lambda { DistanceCalculator.distance(seattle, nyc, reachable) }).
          to raise_error(DistanceError)
      end
    end
  end
end
