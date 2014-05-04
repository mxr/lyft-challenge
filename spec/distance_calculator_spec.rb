# encoding: UTF-8

require 'spec_helper'

require_relative '../lib/coordinate'
require_relative '../lib/detour'
require_relative '../lib/distance_calculator'

describe DistanceCalculator do

  let(:seattle)   { Coordinate.new(47.606209, -122.332071) }
  let(:sunnyvale) { Coordinate.new(37.368830, -122.03635) }
  let(:austin)    { Coordinate.new(30.267153, -97.743061) }
  let(:nyc)       { Coordinate.new(40.714353, -74.005973) }
  let(:moscow)    { Coordinate.new(55.755826, 37.6173) }

  let(:reachable)       { Detour.new(seattle, nyc) }
  let(:unreachable)     { Detour.new(seattle, moscow) }
  let(:invalid_detour)  { Detour.new(seattle, nil) }

  describe '.distance' do
    context 'when computing the distance' do
      it 'returns unreachable for no start' do
        expect(DistanceCalculator.distance(nil, seattle, reachable))
        .to eq(Float::INFINITY)
      end

      it 'returns unreachable for no terminus' do
        expect(DistanceCalculator.distance(seattle, nil, invalid_detour))
        .to eq(Float::INFINITY)
      end

      it 'returns 0 when the start and end are the same with no detour' do
        expect(DistanceCalculator.distance(seattle, seattle.clone))
        .to eq(0)
      end

      it 'returns 0 when the start, end, and detour are the same place' do
        start = nyc
        detour = Detour.new(start.clone, start.clone)
        terminus = start.clone
        expect(DistanceCalculator.distance(start, terminus, detour)).to eq(0)
      end

      it 'returns unreachable for unreachable endpoints' do
        expect(DistanceCalculator.distance(seattle, moscow))
        .to eq(Float::INFINITY)
      end

      it 'returns unreachable for an unreachable detour' do
        expect(DistanceCalculator.distance(seattle, nyc, unreachable))
        .to eq(Float::INFINITY)
      end

      it 'returns unreachable for an invalid detour' do
        expect(DistanceCalculator.distance(seattle, nyc, invalid_detour))
        .to eq(Float::INFINITY)
      end

      it 'returns a reasonable value for no detour' do
        expect(DistanceCalculator.distance(seattle, nyc))
        .to be > 0
      end

      it 'returns a reasonable value for valid detour' do
        expect(DistanceCalculator.distance(seattle, nyc, reachable))
        .to be > 0
      end
    end

    context 'when there is no API key' do
      before { allow(File).to receive(:read).and_raise(Errno::ENOENT) }

      it 'raises an exception' do
        expect(-> { DistanceCalculator.distance(seattle, nyc, reachable) })
        .to raise_error(InvalidAPIKeyError)
      end
    end

    context 'when the API key is invalid' do
      before { allow(File).to receive(:read).and_return('foo') }

      it 'raises an exception' do
        expect(-> { DistanceCalculator.distance(seattle, nyc, reachable) })
        .to raise_error(InvalidAPIKeyError)
      end
    end

    context 'when the server returns 404' do
      before do
        io = double('io')
        io.stub_chain(:status, :first).and_return('404')
        allow(DistanceCalculator).to receive(:open)
                                 .and_raise(OpenURI::HTTPError.new('', io))
        io.stub_chain(:readlines, :first).and_return('{"statusCode":404}')
      end

      it 'returns unreachable' do
        expect(DistanceCalculator.distance(nyc, nyc, unreachable))
        .to eq(Float::INFINITY)
      end
    end

    context 'when the server returns an unsupported error code' do
      before do
        io = double('io')
        io.stub_chain(:status, :first).and_return('403')
        allow(DistanceCalculator).to receive(:open)
                                 .and_raise(OpenURI::HTTPError.new('', io))
      end

      it 'raises an exception' do
        expect(-> { DistanceCalculator.distance(seattle, nyc, reachable) })
        .to raise_error(DistanceError)
      end
    end

    context 'when the server returns a badly-formatted response' do
      before { DistanceCalculator.stub_chain(:open, :read).and_return('foo') }

      it 'raise an exception' do
        expect(-> { DistanceCalculator.distance(seattle, nyc, reachable) })
        .to raise_error(DistanceError)
      end
    end

    context 'when the server returns an incomplete response' do
      before { DistanceCalculator.stub_chain(:open, :read).and_return('{}') }

      it 'raise an exception' do
        expect(-> { DistanceCalculator.distance(seattle, nyc, reachable) })
        .to raise_error(DistanceError)
      end
    end
  end

  describe '.minimum_detour_distance' do
    context 'when given nil or unreachable coordinates' do
      it 'returns unreachable if one of the inputs are nil' do
        expect(DistanceCalculator.minimum_detour_distance(nil, nyc, nyc, nyc))
        .to eq(Float::INFINITY)
      end

      it 'returns unreachable if one of the inputs are nil' do
        expect(DistanceCalculator.minimum_detour_distance(nyc, nil, nyc, nyc))
        .to eq(Float::INFINITY)
      end

      it 'returns unreachable if one of the inputs are nil' do
        expect(DistanceCalculator.minimum_detour_distance(nyc, nyc, nil, nyc))
        .to eq(Float::INFINITY)
      end

      it 'returns unreachable if one of the inputs are nil' do
        expect(DistanceCalculator.minimum_detour_distance(nyc, nyc, nyc, nil))
        .to eq(Float::INFINITY)
      end

      it 'returns unreachable if one of the coordinates is unreachable' do
        expect(
          DistanceCalculator.minimum_detour_distance(nyc, nyc, nyc, moscow)
        ).to eq(Float::INFINITY)
      end
    end

    context 'when given reachable coordinates' do
      before do
        seattle_austin = Detour.new(seattle, austin)
        nyc_sunnyvale  = Detour.new(nyc, sunnyvale)

        allow(Detour).to receive(:new)
                     .with(nyc, sunnyvale)
                     .and_return(nyc_sunnyvale)
        allow(DistanceCalculator).to receive(:distance)
                                 .with(seattle, austin, nyc_sunnyvale)
                                 .and_return(7500)
        allow(DistanceCalculator).to receive(:distance)
                                 .with(seattle, austin)
                                 .and_return(2000)
        allow(Detour).to receive(:new)
                     .with(seattle, austin)
                     .and_return(seattle_austin)
        allow(DistanceCalculator).to receive(:distance)
                                 .with(nyc, sunnyvale, seattle_austin)
                                 .and_return(6700)
        allow(DistanceCalculator).to receive(:distance)
                                 .with(nyc, sunnyvale)
                                 .and_return(2900)
      end

      it 'returns the minimum detour distance' do
        expect(DistanceCalculator.minimum_detour_distance(seattle,
                                                          austin,
                                                          nyc,
                                                          sunnyvale))
        .to eq(3800)
      end
    end
  end

  describe '.build_unescaped_settings_query_string_params' do
    context 'when there is no API key' do
      before { allow(File).to receive(:read).and_raise(Errno::ENOENT) }

      it 'raises an exception' do
        expect(lambda do
          DistanceCalculator
          .send(:build_unescaped_settings_query_string_params)
        end)
        .to raise_error(InvalidAPIKeyError)
      end
    end

    context 'when there is an API key' do
      before { allow(File).to receive(:read).and_return('123') }

      it 'returns params optimized for distance and miles' do
        expect(DistanceCalculator
               .send(:build_unescaped_settings_query_string_params))
        .to eq('key' => '123', 'optmz' => 'distance', 'du' => 'mi')
      end
    end
  end

  describe '.build_unescaped_waypoint_query_string_params' do
    context 'when the parameters are known to be valid' do
      it 'throws an exception (which indicates a programmer error)' do
        expect(lambda do
          DistanceCalculator
          .send(:build_unescaped_waypoint_query_string_params, nil, nil, nil)
        end)
        .to raise_error(StandardError)
      end
    end

    context 'when the parameters are known to be valid is no detour' do
      it 'returns valid params with no detour' do
        expect(DistanceCalculator
               .send(:build_unescaped_waypoint_query_string_params,
                     seattle,
                     nyc,
                     nil))
        .to eq('wp.1' => seattle.to_unescaped_query_string_param,
               'wp.2' => nyc.to_unescaped_query_string_param)
      end

      it 'returns valid params with a detour' do
        expect(DistanceCalculator
               .send(:build_unescaped_waypoint_query_string_params,
                     seattle,
                     nyc,
                     Detour.new(seattle, nyc)))
        .to eq('wp.1' => seattle.to_unescaped_query_string_param,
               'vwp.2' => seattle.to_unescaped_query_string_param,
               'vwp.3' => nyc.to_unescaped_query_string_param,
               'wp.4' => nyc.to_unescaped_query_string_param)
      end
    end
  end

  describe '.build_url_query_string' do
    context 'when encoding any set of params' do
      it 'returns an escaped query string' do
        expect(DistanceCalculator.send(:build_url_query_string,
                                       'a' => '0, 1', '&' => '0, 1'))
        .to eq('a=0%2C+1&%26=0%2C+1')
      end
    end
  end

  describe '.build_bing_routes_url' do
    context 'when building a URL with valid parameters' do
      it 'returns a URL' do
        expect(DistanceCalculator
               .send(:build_bing_routes_url,
                     'key=123&optmz=distance&du=mi&'  \
                     'wp.1=47.606209%2C+-122.332071&' \
                     'wp.2=55.755826%2C+37.6173')
               .to_s)
        .to eq('http://dev.virtualearth.net/REST/v1/Routes/?key=123&' \
               'optmz=distance&du=mi&wp.1=47.606209%2C+-122.332071&'  \
               'wp.2=55.755826%2C+37.6173')
      end
    end
  end

  describe '.fetch_response_from_server' do
    context 'when getting a 404' do
      before do
        io = double('io')
        io.stub_chain(:status, :first).and_return('404')
        allow(DistanceCalculator).to receive(:open)
                                 .and_raise(OpenURI::HTTPError.new('', io))
        io.stub_chain(:readlines, :first).and_return('{}')
      end

      it 'returns the response anyway' do
        expect(DistanceCalculator.send(:fetch_response_from_server, 'asd'))
        .to eq('{}')
      end
    end

    context 'when getting a 401' do
      before do
        io = double('io')
        io.stub_chain(:status, :first).and_return('401')
        allow(DistanceCalculator).to receive(:open)
                                 .and_raise(OpenURI::HTTPError.new('', io))
        io.stub_chain(:readlines, :first).and_return('{}')
      end

      it 'raises an error to indicate the API key is invalid' do
        expect(-> { DistanceCalculator.send(:fetch_response_from_server, '') })
        .to raise_error(InvalidAPIKeyError)
      end
    end

    context 'when getting another kind of error' do
      before do
        io = double('io')
        io.stub_chain(:status, :first).and_return('500')
        allow(DistanceCalculator).to receive(:open)
                                 .and_raise(OpenURI::HTTPError.new('500', io))
      end

      it 'raises an error' do
        expect(-> { DistanceCalculator.send(:fetch_response_from_server, '') })
        .to raise_error(DistanceError)
      end

      it 'returns the code in a message' do
        begin
          DistanceCalculator.send(:fetch_response_from_server, '')
        rescue DistanceError => e
          expect(e.message).to match(/500/)
        end
      end
    end

    context 'when reading the response successfully' do
      before { DistanceCalculator.stub_chain(:open, :read).and_return({}) }

      it 'returns the response' do
        expect(DistanceCalculator.send(:fetch_response_from_server, ''))
        .to eq({})
      end
    end
  end

  describe '.parse_response' do
    context 'when parsing the JSON response' do
      it 'throws an error if the response is invalid' do
        expect(-> { DistanceCalculator.send(:parse_response, '123') })
        .to raise_error(DistanceError)
      end

      it 'returns the response if the response is valid' do
        expect(DistanceCalculator.send(:parse_response, '{}'))
        .to eq({})
      end
    end
  end

  describe '.parse_distance_from_json' do
    context 'when parsing the distance from the json' do
      it 'returns infinity if the status code is 404' do
        expect(DistanceCalculator.send(:parse_distance_from_json,
                                       'statusCode' => 404))
        .to eq(Float::INFINITY)
      end

      it 'returns the distance from a valid response' do
        expect(DistanceCalculator
               .send(:parse_distance_from_json,
                     'resourceSets' =>
                     [{ 'resources' => ['travelDistance' => 100] }]))
        .to eq(100)
      end

      it 'raises an error from an improperly formed response' do
        expect(-> { DistanceCalculator.send(:parse_distance_from_json, {}) })
        .to raise_error(DistanceError)
      end
    end
  end

  describe '.fail_if_invalid_path' do
    context 'when checking a valid path' do
      it 'does not raise an error' do
        DistanceCalculator.send(:fail_if_invalid_path, seattle, nyc, nil)
      end

      it 'does not raise an error' do
        DistanceCalculator
        .send(:fail_if_invalid_path, seattle, nyc, Detour.new(seattle, nyc))
      end
    end

    context 'when checking an invalid path' do
      it 'raises an error' do
        expect(lambda do
          DistanceCalculator.send(:fail_if_invalid_path, seattle, nil, nil)
        end)
        .to raise_error(StandardError)
      end

      it 'raises an error' do
        expect(lambda do
          DistanceCalculator.send(:fail_if_invalid_path, nil, seattle, nil)
        end)
        .to raise_error(StandardError)
      end

      it 'raises an error' do
        expect(lambda do
          DistanceCalculator
          .send(:fail_if_invalid_path, nyc, seattle, Detour.new(seattle, nil))
        end)
        .to raise_error(StandardError)
      end

      it 'raises an error' do
        expect(lambda do
          DistanceCalculator
          .send(:fail_if_invalid_path, nil, nil, Detour.new(nil, nil))
        end)
        .to raise_error(StandardError)
      end
    end
  end

  describe '.invalid_path?' do
    context 'when the path is valid' do
      it 'returns falsy when start, terminus, and detour are valid' do
        expect(DistanceCalculator.send(:invalid_path?,
                                       seattle,
                                       nyc,
                                       Detour.new(sunnyvale, austin)))
        .to be_false
      end

      it 'returns falsy when start and terminus are valid with no detour' do
        expect(DistanceCalculator.send(:invalid_path?, seattle, nyc, nil))
        .to be_false
      end
    end

    context 'when the path is invalid' do
      it 'returns true for no start' do
        expect(DistanceCalculator
               .send(:invalid_path?, nil, nyc, Detour.new(seattle, sunnyvale)))
        .to eq(true)
      end

      it 'returns true for no terminus' do
        expect(DistanceCalculator
               .send(:invalid_path?, nyc, nil, Detour.new(seattle, sunnyvale)))
        .to eq(true)
      end

      it 'returns true for an invalid detour' do
        expect(DistanceCalculator
               .send(:invalid_path?, seattle, nyc, Detour.new(seattle, nil)))
        .to eq(true)
      end
    end
  end

  describe '.no_distance_path?' do
    context 'when checking an invalid path' do
      it 'raises an error for no start or terminus' do
        expect(lambda do
          DistanceCalculator
          .send(:no_distance_path?, nil, nil, Detour.new(seattle, nyc))
        end)
        .to raise_error(StandardError)
      end

      it 'raises an error for an invalid detour' do
        expect(lambda do
          DistanceCalculator
          .send(:no_distance_path?, nyc, seattle, Detour.new(seattle, nil))
        end)
        .to raise_error(StandardError)
      end
    end

    context 'when checking a valid path' do
      it 'returns true for the same start and terminus with no detour' do
        expect(DistanceCalculator
               .send(:no_distance_path?, nyc, nyc.clone, nil))
        .to eq(true)
      end

      it 'returns true for same start & terminus with a no distance detour' do
        expect(DistanceCalculator.send(:no_distance_path?,
                                       nyc,
                                       nyc.clone,
                                       Detour.new(nyc.clone, nyc.clone)))
        .to eq(true)
      end

      it 'returns false if the detour has a distance' do
        expect(DistanceCalculator
               .send(:no_distance_path?, nyc, nyc, Detour.new(seattle, nyc)))
        .to eq(false)
      end

      it 'returns false if the start and end are different' do
        expect(DistanceCalculator.send(:no_distance_path?, seattle, nyc, nil))
        .to eq(false)
      end
    end
  end
end
