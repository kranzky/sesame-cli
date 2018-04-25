# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Sesame::Cave do
  let(:cave) { Sesame::Cave.new(Dir.tmpdir, 20) }

  after do
    cave.close if cave.open?
    cave.forget if cave.locked?
    File.delete(cave.path) if cave.exists?
  end

  describe '#path' do
    it 'returns the location of the sesame cave' do
      expect(cave.path).to eq(File.join(Dir.tmpdir, 'sesame.cave'))
    end
  end

  describe '#item' do
    before do
      phrase = cave.create!
      cave.insert('foo', 'bar')
      cave.close
      cave.open(phrase)
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
    context 'by default' do
      it 'returns false' do
        expect(cave.exists?).to be false
      end
    end

    context 'after #create! and #close' do
      before do
        cave.create!
        cave.close
      end
      it 'returns true' do
        expect(cave.exists?).to be true
      end
    end
  end

  describe '#locked?' do
    context 'by default' do
      it 'returns false' do
        expect(cave.locked?).to be false
      end
    end

    context 'after #create! and #close' do
      before do
        cave.create!
        cave.close
      end
      it 'returns false' do
        expect(cave.locked?).to be false
      end
    end

    context 'after #create! and #lock' do
      before do
        cave.create!
        cave.lock
      end
      it 'returns true' do
        expect(cave.locked?).to be true
      end
    end

    context 'after #create! and #lock and #forget' do
      before do
        cave.create!
        cave.lock
        cave.forget
      end
      it 'returns false' do
        expect(cave.locked?).to be false
      end
    end

    context 'after #create! and #lock and #unlock' do
      before do
        cave.create!
        code = cave.lock
        cave.unlock(code)
      end
      it 'returns false' do
        expect(cave.locked?).to be false
      end
    end
  end

  describe '#open?' do
    context 'by default' do
      it 'returns false' do
        expect(cave.open?).to be false
      end
    end

    context 'after #create!' do
      before do
        cave.create!
      end
      it 'returns true' do
        expect(cave.open?).to be true
      end
    end

    context 'after #create! and #close' do
      before do
        cave.create!
        cave.close
      end
      it 'returns false' do
        expect(cave.open?).to be false
      end
    end

    context 'after #create! and #lock' do
      before do
        cave.create!
        cave.lock
      end
      it 'returns false' do
        expect(cave.open?).to be false
      end
    end

    context 'after @create! and #close and #open' do
      before do
        phrase = cave.create!
        cave.insert('foo', 'bar')
        cave.close
        cave.open(phrase)
      end
      it 'returns true' do
        expect(cave.open?).to be true
      end
    end
  end

  describe '#dirty?' do
    context 'by default' do
      it 'returns false' do
        expect(cave.dirty?).to be false
      end
    end

    context 'after #create!' do
      before do
        cave.create!
      end
      it 'returns true' do
        expect(cave.dirty?).to be true
      end
    end

    context 'after #create! and #close' do
      before do
        cave.create!
        cave.close
      end
      it 'returns false' do
        expect(cave.dirty?).to be false
      end
    end

    context 'after #create! and #lock' do
      before do
        cave.create!
        cave.lock
      end
      it 'returns false' do
        expect(cave.dirty?).to be false
      end
    end

    context 'after @create! and #close and #open' do
      before do
        phrase = cave.create!
        cave.insert('foo', 'bar')
        cave.close
        cave.open(phrase)
      end
      it 'returns false' do
        expect(cave.dirty?).to be false
      end
    end

    context 'after #open and #insert' do
      before do
        phrase = cave.create!
        cave.insert('foo', 'bar')
        cave.close
        cave.open(phrase)
        cave.insert('bar', 'foo')
      end
      it 'returns true' do
        expect(cave.dirty?).to be true
      end
    end

    context 'after #open and #update' do
      before do
        phrase = cave.create!
        cave.insert('foo', 'bar')
        cave.close
        cave.open(phrase)
        cave.update('foo', 'bar')
      end
      it 'returns true' do
        expect(cave.dirty?).to be true
      end
    end

    context 'after #open and #delete' do
      before do
        phrase = cave.create!
        cave.insert('foo', 'bar')
        cave.close
        cave.open(phrase)
        cave.delete('foo', 'bar')
      end
      it 'returns true' do
        expect(cave.dirty?).to be true
      end
    end
  end

  describe '#create!' do
    before do
      cave.create!
    end

    it 'creates a new cave' do
      expect(cave.exists?).to be false
      expect(cave.locked?).to be false
      expect(cave.open?).to be true
    end
  end

  describe '#open' do
    before do
      phrase = cave.create!
      cave.insert('foo', 'bar')
      cave.close
      cave.open(phrase)
      cave.get('foo')
    end
    it 'opens an existing cave' do
      expect(cave.exists?).to be true
      expect(cave.locked?).to be false
      expect(cave.open?).to be true
      expect(cave.item[:user]).to eq('bar')
    end
  end

  describe '#close' do
    before do
      cave.create!
      cave.insert('foo', 'bar')
      cave.close
    end
    it 'closes a cave' do
      expect(cave.exists?).to be true
      expect(cave.locked?).to be false
      expect(cave.open?).to be false
    end
  end

  describe '#lock' do
    before do
      cave.create!
      cave.insert('foo', 'bar')
      cave.lock
    end
    it 'locks a cave' do
      expect(cave.exists?).to be true
      expect(cave.locked?).to be true
      expect(cave.open?).to be false
    end
  end

  describe '#unlock' do
    before do
      cave.create!
      cave.insert('foo', 'bar')
      phrase = cave.lock
      cave.unlock(phrase)
      cave.get('foo')
    end
    it 'unlocks a cave' do
      expect(cave.exists?).to be true
      expect(cave.locked?).to be false
      expect(cave.open?).to be true
      expect(cave.item[:user]).to eq('bar')
    end
  end

  describe '#forget' do
    before do
      cave.create!
      cave.insert('foo', 'bar')
      cave.lock
      cave.forget
    end
    it 'removes the lock file' do
      expect(cave.exists?).to be true
      expect(cave.locked?).to be false
      expect(cave.open?).to be false
    end
  end

  describe '#index' do
    before do
      cave.create!
      cave.insert('foo', 'bar')
      cave.insert('foo', 'xxx')
      cave.insert('bar', 'foo')
    end
    let(:index) { cave.index }
    it 'returns the contents of the cave' do
      expect(index.count).to eq(3)
      expect(index.keys[0]).to eq('bar')
      expect(index.keys[2]).to eq('sesame')
      expect(index['foo'].count).to eq(2)
      expect(index['foo']['xxx']).to eq(0)
    end
  end

  describe '#unique?' do
    before do
      cave.create!
      cave.insert('foo', 'bar')
      cave.insert('foo', 'xxx')
      cave.insert('bar', 'foo')
    end
    it 'returns true for services that contain exactly one user' do
      expect(cave.unique?('foo')).to be false
      expect(cave.unique?('bar')).to be true
      expect { cave.unique?('xxx') }.to raise_error(Sesame::Fail)
    end
  end

  describe '#get' do
    before do
      cave.create!
      cave.insert('foo', 'bar')
      cave.insert('foo', 'xxx')
    end
    let!(:phrase) { cave.insert('bar', 'foo') }
    it 'returns the phrase' do
      expect(cave.item[:index]).to eq(0)
      expect(cave.get('bar')).to eq(phrase)
      expect(cave.get('bar', 'foo')).to eq(phrase)
      expect { cave.get('foo') }.to raise_error(Sesame::Fail)
      expect { cave.get('xxx') }.to raise_error(Sesame::Fail)
      expect(cave.get('foo', 'xxx').split(' ').count).to eq(4)
    end
  end

  describe '#insert' do
    before do
      cave.create!
      cave.insert('foo', 'bar')
    end
    it 'inserts the item' do
      expect(cave.item[:service]).to eq('foo')
      expect(cave.item[:user]).to eq('bar')
      expect(cave.item[:index]).to eq(0)
      expect { cave.insert('foo', 'bar') }.to raise_error(Sesame::Fail)
      expect(cave.insert('foo', 'xxx').split(' ').count).to eq(4)
      expect(cave.item[:user]).to eq('xxx')
    end
  end

  describe '#update' do
    before do
      cave.create!
    end
    let!(:phrase) { cave.insert('foo', 'bar') }
    it 'updates the item' do
      expect(cave.item[:index]).to eq(0)
      expect(cave.get('foo')).to eq(phrase)
      expect(cave.update('foo')).not_to eq(phrase)
      expect(cave.item[:index]).to eq(1)
      expect(cave.get('foo')).not_to eq(phrase)
    end
  end

  describe '#delete' do
    before do
      cave.create!
      cave.insert('foo', 'bar')
    end
    let!(:phrase) { cave.insert('bar', 'foo') }
    it 'deletes the item' do
      expect(cave.get('bar')).to eq(phrase)
      expect(cave.delete('bar')).to eq(phrase)
      expect { cave.get('bar') }.to raise_error(Sesame::Fail)
      expect(cave.item[:service]).to eq('bar')
      expect { cave.get('xxx') }.to raise_error(Sesame::Fail)
    end
  end
end
