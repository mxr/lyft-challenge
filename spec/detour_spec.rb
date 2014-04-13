require 'spec_helper'

require_relative '../detour'
require_relative '../dist_calc'

describe Detour do

  let(:a) { Coordinate.new(0, 0) }
  let(:b) { Coordinate.new(1, 1) }

  let(:different_locations) { Detour.new(a, b) }
  let(:same_location) { Detour.new(a, a.clone) }
  let(:first_nil_location) { Detour.new(a, nil) }
  let(:second_nil_location) { Detour.new(nil, a) }
  let(:nil_locations) { Detour.new(nil, nil) }

  describe '#valid?' do
    context 'when checking validity' do
      it 'returns true for two non-nil Coordinates' do
        expect(different_locations.valid?).to be true
      end

      it 'returns true when both Coordinates are the same location' do
        expect(same_location.valid?).to be true
      end

      it 'returns false when the first Coordinate is nil' do
        expect(first_nil_location.valid?).to be false
      end

      it 'returns false when the second Coordinate is nil' do
        expect(second_nil_location.valid?).to be false
      end

      it 'returns true when both Coordinates are nil' do
        expect(nil_locations.valid?).to be true
      end
    end
  end

  describe '#no_distance?' do
    context 'when checking if the detour covers no distance' do
      it 'returns false for two non-nil Coordinates' do
        expect(different_locations.no_distance?).to be false
      end

      it 'returns true when both Coordinates are the same location' do
        expect(same_location.no_distance?).to be true
      end

      it 'returns true when the first Coordinate is nil' do
        expect(first_nil_location.no_distance?).to be true
      end

      it 'returns true when the second Coordinate is nil' do
        expect(second_nil_location.no_distance?).to be true
      end

      it 'returns true when both Coordinates are nil' do
        expect(nil_locations.no_distance?).to be true
      end
    end
  end
end
