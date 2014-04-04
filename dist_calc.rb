#!/usr/bin/ruby

require 'cgi'
require 'json'
require 'open-uri'
require 'uri'

# Class to represent a coordinate on Earth.
class Coordinate

  attr_accessor :latitude, :longitude

  def initialize(latitude, longitude)
    @latitude, @longitude = latitude, longitude
  end

  def to_unescaped_query_param
    "#{@latitude}, #{@longitude}"
  end

  def ==(other)
    [@latitude, @longitude] == [other.latitude, other.longitude]
  end

  # Computes the distance between this coordinate and another coordinate
  # while optionally stopping at the coordinates given as detour_start and
  # detour_end. Returns the distance in miles or Float::INFINITY if the
  # distance is not reachable.
  def distance(other, detour_start = nil, detour_end = nil)

    def invalid_detour(detour_start, detour_end)
      [detour_start, detour_end].compact.size == 1
    end

    return Float::INFINITY if invalid_detour(detour_start, detour_end)

    # Check for the degenerate case when start-and-end pairs are the same, and
    # the detour points are the same as the start (or there are no detours).
    return 0 if (self == other and detour_start == detour_end) and
                (detour_start.nil? or self == detour_start)

    # Compute the distance between this coordinate and the others using the
    # Bing Maps API. Unreachable distances cause us to return a distance of
    # Float::INFINITY to the caller.

    host = 'dev.virtualearth.net'
    path = '/REST/v1/Routes/'

    unescaped_query_params =
      {'key'   => File.read('key.txt').strip, # Bing Maps API key
       'optmz' => 'distance',                 # Optimize for distance
       'du'    => 'mi',                       # Return the result in miles
       'wp.1'  => self.to_unescaped_query_param}

    unescaped_waypoint_query_params =
      if detour_start and detour_end
        {'vwp.2' => detour_start.to_unescaped_query_param,
         'vwp.3' => detour_end.to_unescaped_query_param,
         'wp.4'  => other.to_unescaped_query_param}
      else
        {'wp.2' => other.to_unescaped_query_param}
      end

    escaped_query =
      unescaped_query_params.merge(unescaped_waypoint_query_params).map do |k,v|
        "#{k}=#{CGI.escape(v)}"
      end.join('&')

    url = URI::HTTP.build(:host => host, :path => path, :query => escaped_query)

    begin
      response = JSON.parse(open(url).read)
    rescue OpenURI::HTTPError => e
      # 404 is raised when a location is unreachable.
      if e.message.start_with?('404')
        return Float::INFINITY
      else
        abort("Server error: #{e.message}")
      end
    end

    return response['resourceSets'][0]['resources'][0]['travelDistance']

  end

  # Adapted from the challenge description: Given four latitude / longitude
  # pairs, where driver one is traveling from coordinate A to coordinate B and
  # driver two is traveling from coordinate C to coordinate D, this function
  # calculates the shorter of the detour distances the drivers would need to
  # take to pick-up and drop-off the other driver.
  # For example if the driver
  # meant to go from A to B but had to go to C and D first then the detour
  # distance is ACDB - AB. The minimum detour distance is simply the minimum of
  # the possible detour combinations (which could be Float::INFINITY if one
  # place is unreachable).
  def self.min_detour_distance(a, b, c, d)

    # Input validation
    if (a.nil? or b.nil? or c.nil? or d.nil?)
      return Float::INFINITY
    end

    # If a detour is unreachable, this means one of the coordinates is on an
    # "undrivable island", so the other distances will also be unreachable and
    # we don't need to check them.
    acdb = a.distance(b, c, d)
    if (acdb == Float::INFINITY)
      Float::INFINITY
    else
      ab_detour_distance = acdb - a.distance(b)
      cd_detour_distance = c.distance(d, a, b) - c.distance(d)
      [ab_detour_distance, cd_detour_distance].min
    end
  end
end

# CLI app (tested ad-hoc).
if __FILE__ == $0
  require 'optparse'

  @usage = "Usage: #{$0} -A lat,long -B lat,long -C lat,long -D lat,long"

  # Helper to sanitize/normalize input.
  def sanitize_and_normalize(arg)
    lat_and_long = arg.map(&:to_f)
    abort(@usage) if lat_and_long.length != 2
    lat_and_long
  end

  # Parse arguments.
  locations = {}
  OptionParser.new do |options|

    options.banner = @usage

    options.on('-A lat,long', Array) do |a|
      locations['a'] = Coordinate.new(* sanitize_and_normalize(a))
    end
    options.on('-B lat,long', Array) do |b|
      locations['b'] = Coordinate.new(* sanitize_and_normalize(b))
    end
    options.on('-C lat,long', Array) do |c|
      locations['c'] = Coordinate.new(* sanitize_and_normalize(c))
    end
    options.on('-D lat,long', Array) do |d|
      locations['d'] = Coordinate.new(* sanitize_and_normalize(d))
    end
  end.parse!

  # Determine the minimum detour distance.
  abort(@usage) if locations.length < 4
  dist = Coordinate.min_detour_distance(* locations.values_at( *%w[a b c d]) )
  if dist == Float::INFINITY
    puts 'Unreachable destinations.'
  else
    puts "The minimum detour distance is #{dist} mi."
  end
end
