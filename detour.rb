#!/usr/bin/env ruby

# Class to represent a detour, which holds a start and end Coordinate.
class Detour

  attr_accessor :start, :terminus

  def initialize(start, terminus)
    @start = start
    @terminus = terminus
  end

  def valid?
    @start.nil? ? @terminus.nil? : (not @terminus.nil?)
  end

  def invalid?
    not valid?
  end

  def no_distance?
    @start == nil || @terminus == nil || @start == @terminus
  end
end
