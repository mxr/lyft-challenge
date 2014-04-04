require_relative '../dist_calc'

describe Coordinate do

  let(:latitude)  { 0 }
  let(:longitude) { 1 }
  subject { Coordinate.new(latitude, longitude) }

  describe '#to_unescaped_query_param' do
    context 'when serializing the object' do
      it 'prints both latitude and longitude' do
        expect(subject.to_unescaped_query_param).to eq('0, 1')
      end
    end
  end

  describe '#==' do
    context 'when comparing the object' do
      it 'succeeds when given another Coordinate with the same lat and long' do
        expect(subject).to eq(subject.clone)
      end

      it 'fails when given a Coordinate with a different lat and long' do
        expect(subject).not_to eq(Coordinate.new(subject.latitude+1, 0))
      end
    end
  end

  let(:seattle)   { Coordinate.new(47.606209, -122.332071) }
  let(:sunnyvale) { Coordinate.new(37.368830, -122.03635) }
  let(:austin)    { Coordinate.new(30.267153, -97.743061) }
  let(:nyc)       { Coordinate.new(40.714353, -74.005973) }
  let(:moscow)    { Coordinate.new(55.755826, 37.6173) }

  describe '#distance' do
    context 'when given an endpoint and one detour point' do
      it 'returns unreachable' do
        expect(seattle.distance(sunnyvale, nyc, nil)).to eq(Float::INFINITY)
      end

      it 'returns unreachable' do
        expect(seattle.distance(sunnyvale, nil, nyc)).to eq(Float::INFINITY)
      end
    end

    context 'when given an unreachable endpoint' do
      it 'returns unreachable' do
        expect(seattle.distance(moscow, austin, nyc)).to eq(Float::INFINITY)
      end
    end

    context 'when given an unreachable detour' do
      it 'returns unreachable' do
        expect(seattle.distance(austin, moscow, nyc)).to eq(Float::INFINITY)
      end

      it 'returns unreachable' do
        expect(seattle.distance(austin, nyc, moscow)).to eq(Float::INFINITY)
      end
    end

    context 'when given a duplicate endpoint' do
      it 'returns zero' do
        expect(seattle.distance(seattle.clone, nil, nil)).to eq 0
      end
    end

    context 'when given a duplicate endpoint and detours' do
      it 'returns zero' do
        expect(nyc.distance(nyc.clone, nyc.clone, nyc.clone)).to eq 0
      end
    end

    context 'when given a reachable endpoint' do
      it 'returns a positive value' do
        expect(seattle.distance(sunnyvale, nil, nil)).to be > 0
      end
    end

    context 'when given a reachable endpoint with reachable detours' do
      it 'returns a positive value' do
        expect(seattle.distance(sunnyvale, austin, nyc)).to be > 0
      end
    end

    context 'when the server returns an unexpected error' do
      let(:http_error)  { OpenURI::HTTPError.new('500', double('io')) }
      let(:system_exit) { SystemExit.new(http_error.message) }

      before do
        allow_any_instance_of(Coordinate)
                  .to receive(:open)
                  .with(an_instance_of(URI::HTTP))
                  .and_raise(http_error)
        allow_any_instance_of(Coordinate)
                  .to receive(:abort)
                  .with(an_instance_of(String))
                  .and_raise(system_exit)
      end

      it 'should exit' do
        expect(
          lambda do
            Coordinate.min_detour_distance(seattle, austin, nyc, sunnyvale)
          end
        ).to raise_error(system_exit)
      end
    end
  end

  describe '.min_detour_distance' do
    context 'when given a reachable detour' do
      it 'returns a positive value' do
        expect(Coordinate.min_detour_distance(seattle, austin, nyc, sunnyvale))
               .to be > 0
      end
    end

    context 'when given an unreachable detour' do
      it 'returns unreachable' do
        expect(Coordinate.min_detour_distance(seattle, austin, moscow, nyc))
               .to eq(Float::INFINITY)
      end
    end

    context 'when given a nil coordinate' do
      it 'returns unreachable' do
        expect(Coordinate.min_detour_distance(seattle, nil, nil, nil))
               .to eq(Float::INFINITY)
      end

      it 'returns unreachable' do
        expect(Coordinate.min_detour_distance(nil, seattle, nil, nil))
               .to eq(Float::INFINITY)
      end

      it 'returns unreachable' do
        expect(Coordinate.min_detour_distance(nil, nil, seattle, nil))
               .to eq(Float::INFINITY)
      end

      it 'returns unreachable' do
        expect(Coordinate.min_detour_distance(nil, nil, nil, seattle))
               .to eq(Float::INFINITY)
      end
    end
  end
end

