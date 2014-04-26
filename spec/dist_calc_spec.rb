# encoding: UTF-8

# This gem is used to read stderr and as a cross-platform way to suppress
# command output.
require 'open3'

require 'spec_helper'

require_relative '../dist_calc'
require_relative '../lib/coordinate'

describe 'dist_calc CLI app' do
  context 'when passing in invalid arguments' do
    it 'returns an error for no arguments' do
      Open3.popen3('ruby dist_calc.rb') do |_, _, _, thread|
        expect(thread.value).to_not eq(0)
      end
    end

    it 'returns an error if an argument is missing' do
      Open3.popen3('ruby dist_calc.rb -C 0,0') do |_, _, _, thread|
        expect(thread.value).to_not eq(0)
      end
    end

    it 'returns an error if arguments are badly formatted' do
      command = 'ruby dist_calc.rb -A -B 0 -C 1,2,3 -D asd'
      Open3.popen3(command) do |_, _, _, thread|
        expect(thread.value).to_not eq(0)
      end
    end
  end

  context 'when passing in valid Coordinates' do
    let(:seattle)   { Coordinate.new(47.606209, -122.332071) }
    let(:sunnyvale) { Coordinate.new(37.368830, -122.03635) }
    let(:austin)    { Coordinate.new(30.267153, -97.743061) }
    let(:nyc)       { Coordinate.new(40.714353, -74.005973) }
    let(:moscow)    { Coordinate.new(55.755826, 37.6173) }

    def build_args(a, b, c, d)
      options = %w[-A -B -C -D]
      coordinates = [a, b, c, d]

      options.zip(coordinates).map do |(option, coordinate)|
        "#{option} #{coordinate.latitude},#{coordinate.longitude}"
      end.join(' ')
    end

    let(:reachable_args)   { build_args(seattle, sunnyvale, austin, nyc) }
    let(:unreachable_args) { build_args(moscow, sunnyvale, austin, nyc) }

    it 'returns success with valid coordinates' do
      Open3.popen3("ruby dist_calc.rb #{reachable_args}") do |_, _, _, thread|
        expect(thread.value.exitstatus).to be 0
      end
    end

    it 'tells the user the output with valid coordinates' do
      Open3.popen3("ruby dist_calc.rb #{reachable_args}") do |_, stdout, _, _|
        expect(stdout.read.downcase).to match(/\d+ mi/)
      end
    end

    it 'returns an error if the distance is unreachable' do
      Open3.popen3("ruby dist_calc.rb #{unreachable_args}") do |_, _, _, thread|
        expect(thread.value.exitstatus).to_not eq(0)
      end
    end

    it 'tells the user the distance is unreachable if that is the case' do
      Open3.popen3("ruby dist_calc.rb #{unreachable_args}") do |_, _, stderr, _|
        expect(stderr.read.downcase).to match(/unreachable/)
      end
    end
  end
end
