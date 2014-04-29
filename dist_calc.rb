#!/usr/bin/env ruby
# encoding: UTF-8

# CLI app for computing the minimum detour distance between four Coordinates.
if __FILE__ == $0
  require 'rubygems'
  require 'bundler/setup'

  require 'optparse'

  require_relative 'lib/coordinate'
  require_relative 'lib/distance_calculator'

  @usage = "Usage: #{$0} -A lat,long -B lat,long -C lat,long -D lat,long"

  def sanitize_and_normalize(arg)
    lat_and_long = arg.map(&:to_f)
    abort(@usage) if lat_and_long.length != 2
    lat_and_long
  end

  OPTION_SWITCHES = %w(-A -B -C -D)
  coordinates = {}
  OptionParser.new do |options|

    options.banner = @usage

    OPTION_SWITCHES.each do |switch|
      options.on("#{switch} lat,long", Array) do |coordinate_string|
        coordinate = Coordinate.new(* sanitize_and_normalize(coordinate_string))
        coordinates[switch] = coordinate
      end
    end
  end.parse!

  abort(@usage) if coordinates.length < 4

  puts 'Calculating...'

  begin
    a, b, c, d = coordinates.values_at(* OPTION_SWITCHES)
    distance = DistanceCalculator.minimum_detour_distance(a, b, c, d)
  rescue DistanceError
    abort('Routing server returned an error.')
  rescue InvalidAPIKeyError
    abort('Bing Routes API key is invalid.')
  end

  if distance == Float::INFINITY
    abort('Unreachable destinations.')
  else
    puts "The minimum detour distance is #{'%.2f' % distance} mi."
  end
end
