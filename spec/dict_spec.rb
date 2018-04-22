# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Sesame::Dict do
  let(:dict) { Sesame::Dict.load }

  describe '#load' do
    it 'returns 2048 unique words' do
      expect(dict.sort.uniq.count).to eq(2048)
    end
  end
end
