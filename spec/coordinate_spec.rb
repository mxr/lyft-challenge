# encoding: UTF-8

require 'spec_helper'

require_relative  '../lib/coordinate'

describe Coordinate do
  subject(:coordinate) { Coordinate.new(1, 0) }

  describe '#==' do
    context 'when checking equality' do
      it 'returns not equal when the other Coordinate is nil' do
        expect(coordinate).not_to eq(nil)
      end

      it 'returns not equal when the other has a different latitude' do
        expect(coordinate).not_to eq(Coordinate.new(coordinate.latitude+1, 0))
      end

      it 'returns not equal when the other has a different longitude' do
        expect(coordinate).not_to eq(Coordinate.new(0, coordinate.longitude+1))
      end

      it 'returns equal when the other coordinate has the same lat and long' do
        expect(coordinate).
          to eq(Coordinate.new(coordinate.latitude, coordinate.longitude))
      end
    end
  end

  describe '#to_unescaped_query_param' do
    context 'when serializing to a query parameter' do
      it 'must match a specific format' do
        expect(coordinate.to_unescaped_query_param).
          to eq "#{coordinate.latitude}, #{coordinate.longitude}"
      end
    end
  end
end
