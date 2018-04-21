# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Sesame::Cave do
  let(:cave) { Sesame::Cave.new(Dir.tmpdir, 20) }

  describe '#path' do
    it 'returns the location of the sesame cave' do
      expect(cave.path).to eq(File.join(Dir.tmpdir, 'sesame.cave'))
    end
  end

  describe '#item' do
    before do
      File.delete(cave.path) if cave.exists?
      cave.forget if cave.locked?
      phrase = cave.create!
      cave.insert('foo', 'bar')
      cave.close
      cave.open(phrase)
    end

    after do
      cave.close if cave.open?
    end

    it 'returns nothing by default' do
      expect(cave.item).to be_nil
    end

    context 'after #get' do
      before do
        cave.get('foo')
      end
      it 'returns the item' do
        expect(cave.item[:user]).to eq('bar')
      end
    end

    context 'after #insert' do
      before do
        cave.insert('xxx', 'yyy')
      end
      it 'returns the item' do
        expect(cave.item[:user]).to eq('yyy')
      end
    end

    context 'after #update' do
      before do
        cave.update('foo')
      end
      it 'returns the item' do
        expect(cave.item[:user]).to eq('bar')
      end
    end

    context 'after #delete' do
      before do
        cave.delete('foo')
      end
      it 'returns the item' do
        expect(cave.item[:user]).to eq('bar')
      end
    end

    context 'after #lock' do
      before do
        cave.insert('xxx', 'yyy')
        cave.lock
      end
      it 'is cleared' do
        expect(cave.item).to be_nil
      end
    end
  end

  describe '#exists?' do
  end

  describe '#locked?' do
  end

  describe '#open?' do
  end

  describe '#dirty?' do
  end

  describe '#create!' do
  end

  describe '#open' do
  end

  describe '#close' do
  end

  describe '#lock' do
  end

  describe '#unlock' do
  end

  describe '#forget' do
  end

  describe '#index' do
  end

  describe '#unique?' do
  end

  describe '#get' do
  end

  describe '#insert' do
  end

  describe '#update' do
  end

  describe '#delete' do
  end
end