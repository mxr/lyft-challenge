#!/usr/bin/env ruby

# CLI app for computing the minimum detour distance between four Coordinates.
if __FILE__ == $0
  require 'optparse'

  require_relative 'lib/coordinate'
  require_relative 'lib/distance_calculator'

  @usage = "Usage: #{$0} -A lat,long -B lat,long -C lat,long -D lat,long"

  def sanitize_and_normalize(arg)
    lat_and_long = arg.map(&:to_f)
    abort(@usage) if lat_and_long.length != 2
    lat_and_long
  end

  coordinates = {}
  OptionParser.new do |options|

    options.banner = @usage

    %w[-A -B -C -D].each do |option|
      options.on("#{option} lat,long", Array) do |coordinate_string|
        coordinate = Coordinate.new(* sanitize_and_normalize(coordinate_string))
        coordinates[option] = coordinate
      end
    end
  end.parse!

  abort(@usage) if coordinates.length < 4

  begin
    a, b, c, d = coordinates.values_at(* %w[-A -B -C -D])
    distance = DistanceCalculator.minimum_detour_distance(a, b, c, d)
  rescue DistanceError
    abort('Routing server returned an error.')
  end

  if distance == Float::INFINITY
    abort('Unreachable destinations.')
  else
    puts "The minimum detour distance is #{distance} mi."
  end
end
