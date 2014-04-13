#!/usr/bin/env ruby

require_relative 'coordinate'

# Class to compute distances between given Coordinates.
class DistanceCalculator

  # Compute the distance between start and terminus while passing through an
  # optional detour. Returns the distance in miles or Float::INFINITY if there
  # is no path between the given points. Raises a DistanceError if there is an
  # issue that prohibits it from returning a distance or determing that there
  # is no path between the given points.
  def self.distance(start, terminus, detour = nil)
    if start.nil? || terminus.nil? || detour && detour.invalid?
      return Float::INFINITY
    end

    if start == terminus
      return 0 if detour.nil? || start == detour.start && detour.no_distance?
    end

    unescaped_query_params =
      {'key'   => File.read('key.txt').strip, # Bing Maps API key
       'optmz' => 'distance',                 # Optimize for distance
       'du'    => 'mi'}                       # Return the result in miles

    unescaped_waypoint_query_params =
      {'wp.1'  => start.to_unescaped_query_param}
        .merge(
          if detour
            {'vwp.2' => detour.start.to_unescaped_query_param,
             'vwp.3' => detour.terminus.to_unescaped_query_param,
             'wp.4'  => terminus.to_unescaped_query_param}
          else
            {'wp.2' => terminus.to_unescaped_query_param}
          end)

    escaped_query =
      unescaped_query_params.merge(unescaped_waypoint_query_params).map do |k,v|
        "#{k}=#{CGI.escape(v)}"
      end.join('&')

    url = URI::HTTP.build(:host => 'dev.virtualearth.net',
                          :path => '/REST/v1/Routes/',
                          :query => escaped_query)

    begin
      response = JSON.parse(open(url).read)
    rescue OpenURI::HTTPError => e
      code = e.io.status.first.to_i
      if code == 404
        # 404 is raised when a location is unreachable.
        return Float::INFINITY
      else
        raise DistanceError.new("#{code} returned from routing server.")
      end
    rescue JSON::ParserError
      raise DistanceError.new('Invalid response received from routing server.')
    end

    begin
      distance = response['resourceSets'][0]['resources'][0]['travelDistance']
    rescue NoMethodError
      message = 'Incomplete response received from routing server.'
      raise DistanceError.new(message)
    end
  end
end

# Error that the DistanceCalculator throws in case of an issue that prohibits
# it from returning a distance or determing that there is no path between the
# given points.
class DistanceError < StandardError
end
