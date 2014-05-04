#!/usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'bundler/setup'

require 'cgi'
require 'json'
require 'open-uri'
require 'uri'

require_relative 'coordinate'
require_relative 'detour'

# Class to compute distances between given Coordinates.
class DistanceCalculator
  # Compute the distance between start and terminus while passing through an
  # optional detour. Returns the distance in miles or Float::INFINITY if there
  # is no path between the given points. Raises a DistanceError if there is an
  # issue that prohibits it from returning a distance or determing that there
  # is no path between the given points. Performs a blocking network
  # operation.
  def self.distance(start, terminus, detour = nil)
    return Float::INFINITY if invalid_path?(start, terminus, detour)
    return 0 if no_distance_path?(start, terminus, detour)

    unescaped_settings_qsp = build_unescaped_settings_query_string_params
    unescaped_waypoint_qsp =
      build_unescaped_waypoint_query_string_params(start, terminus, detour)

    escaped_query_string =
      build_url_query_string(unescaped_settings_qsp
                             .merge(unescaped_waypoint_qsp))

    url = build_bing_routes_url(escaped_query_string)

    parse_distance_from_json(parse_response(fetch_response_from_server(url)))
  end

  # Adapted from the challenge description: Given four latitude / longitude
  # pairs, where driver one is traveling from coordinate A to coordinate B and
  # driver two is traveling from coordinate C to coordinate D, this function
  # calculates the shorter of the detour distances the drivers would need to
  # take to pick-up and drop-off the other driver.
  # For example if the driver meant to go from A to B but had to go to C and D
  # first then the detour distance is ACDB - AB. The minimum detour distance is
  # simply the minimum of the possible detour combinations (which could be
  # Float::INFINITY if one place is unreachable).
  def self.minimum_detour_distance(a, b, c, d)
    return Float::INFINITY unless a && b && c && d

    acdb = DistanceCalculator.distance(a, b, Detour.new(c, d))
    if acdb == Float::INFINITY
      # If any path is unreachable, this means one of the coordinates is on an
      # "undrivable island", so the other distances will also be unreachable
      # and we don't need to check them.
      Float::INFINITY
    else
      ab_detour_distance = acdb - DistanceCalculator.distance(a, b)

      cabd = DistanceCalculator.distance(c, d, Detour.new(a, b))
      cd_detour_distance = cabd - DistanceCalculator.distance(c, d)

      [ab_detour_distance, cd_detour_distance].min
    end
  end

  class << self
    private

    def build_unescaped_settings_query_string_params
      begin
        key = File.read(File.join(File.dirname(__FILE__), '../config/key.txt'))
                  .strip
      rescue Errno::ENOENT
        raise InvalidAPIKeyError, 'Bing Routes API key not at config/key.txt'
      end

      { 'key'   => key,        # Bing Routes API key
        'optmz' => 'distance', # Optimize for distance
        'du'    => 'mi' }      # Return the result in miles
    end

    def build_unescaped_waypoint_query_string_params(start, terminus, detour)
      fail_if_invalid_path(start, terminus, detour)

      start = { 'wp.1'  => start.to_unescaped_query_string_param }
      rest = if detour
               { 'vwp.2' => detour.start.to_unescaped_query_string_param,
                 'vwp.3' => detour.terminus.to_unescaped_query_string_param,
                 'wp.4'  => terminus.to_unescaped_query_string_param }
             else
               { 'wp.2' => terminus.to_unescaped_query_string_param }
             end

      start.merge(rest)
    end

    def build_url_query_string(unescaped_params)
      unescaped_params.map do |k, v|
        "#{CGI.escape(k)}=#{CGI.escape(v)}"
      end.join('&')
    end

    def build_bing_routes_url(escaped_query_string)
      URI::HTTP.build(host:  'dev.virtualearth.net',
                      path:  '/REST/v1/Routes/',
                      query: escaped_query_string)
    end

    def fetch_response_from_server(url)
      open(url).read
    rescue OpenURI::HTTPError => e
      code = e.io.status.first.to_i
      case code
      when 404
        # This means the path is unreachable. We can still return the response.
        e.io.readlines.first
      when 401 then raise InvalidAPIKeyError, 'Invalid Bing Routes API key'
      else raise DistanceError, "#{code} returned from routing server."
      end
    end

    def parse_response(response)
      JSON.parse(response)
    rescue JSON::ParserError
      raise DistanceError, 'Invalid response received from routing server.'
    end

    def parse_distance_from_json(json)
      if json['statusCode'] == 404
        Float::INFINITY
      else
        json['resourceSets'][0]['resources'][0]['travelDistance']
      end
    rescue NoMethodError
      raise DistanceError, 'Incomplete response received from routing server.'
    end

    def fail_if_invalid_path(start, terminus, detour)
      if invalid_path?(start, terminus, detour)
        fail StandardError, 'Path must be valid before calling this method.'
      end
    end

    def invalid_path?(start, terminus, detour)
      start.nil? || terminus.nil? || detour && detour.invalid?
    end

    def no_distance_path?(start, terminus, detour)
      fail_if_invalid_path(start, terminus, detour)

      start == terminus &&
        (detour.nil? || start == detour.start && detour.no_distance?)
    end
  end
end

# Error that the DistanceCalculator throws in case of an issue that prohibits
# it from returning a distance or determing that there is no path between the
# given points.
class DistanceError < StandardError
end

# Error that the DistanceCalculator throws when the API key is invalid.
class InvalidAPIKeyError < StandardError
end
