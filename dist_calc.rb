#!/usr/bin/env ruby
# encoding: UTF-8

# CLI app for computing the minimum detour distance between four Coordinates.
if __FILE__ == $PROGRAM_NAME
  require 'rubygems'
  require 'bundler/setup'

  require 'optparse'

  require_relative 'lib/coordinate'
  require_relative 'lib/distance_calculator'

  USAGE =
    "Usage: #{$PROGRAM_NAME} -A lat,long -B lat,long -C lat,long -D lat,long"

  def sanitize_and_normalize(arg)
    lat_and_long = arg.map(&:to_f)
    abort(USAGE) if lat_and_long.length != 2
    lat_and_long
  end

  OPTION_SWITCHES = %w(-A -B -C -D)
  coordinates = {}
  OptionParser.new do |options|

    options.banner = USAGE

    OPTION_SWITCHES.each do |switch|
      options.on("#{switch} lat,long", Array) do |coordinate_string|
        sanitized_args = sanitize_and_normalize(coordinate_string)
        coordinate = Coordinate.new(* sanitized_args)
        coordinates[switch] = coordinate
      end
    end
  end.parse!

  abort(USAGE) if coordinates.length < 4

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
    puts "The minimum detour distance is #{format('%.2f', distance)} mi."
  end
end
