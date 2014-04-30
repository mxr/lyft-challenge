#!/usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'bundler/setup'

require_relative 'coordinate'

# Class to represent a detour, which holds a start and end Coordinate.
class Detour
  attr_accessor :start, :terminus

  def initialize(start, terminus)
    @start, @terminus = start, terminus
  end

  def valid?
    !invalid?
  end

  def invalid?
    @start.nil? ^ @terminus.nil? # => Invalid when only one Coordinate is set.
  end

  def no_distance?
    @start.nil? || @terminus.nil? || @start == @terminus
  end
end
