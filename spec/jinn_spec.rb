# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Sesame::Jinn do
  let(:opts) { double('opts') }
  let(:jinn) { Sesame::Jinn.new(opts) }

  before do
    option = double('option')
    allow(opts).to receive(:echo?) { true }
    allow(opts).to receive(:interactive?) { false }
    allow(opts).to receive(:quiet?) { true }
    allow(opts).to receive(:list?) { false }
    allow(opts).to receive(:add?) { false }
    allow(opts).to receive(:get?) { false }
    allow(opts).to receive(:next?) { false }
    allow(opts).to receive(:delete?) { false }
    allow(opts).to receive(:lock?) { false }
    allow(opts).to receive(:expunge?) { false }
    allow(opts).to receive(:reconstruct?) { false }
    allow(opts).to receive(:[]) { '/tmp' }
    allow(opts).to receive(:option) { option }
    allow(option).to receive(:ensure_call)
  end

  after do
    cave = jinn.instance_variable_get(:@cave)
    cave.close if cave.open?
    cave.forget if cave.locked?
    File.delete(cave.path) if cave.exists?
  end

  describe '#process!' do
    context 'no arguments supplied' do
      it 'exits with an error message' do
        jinn.process!
      end
    end
  end
end
