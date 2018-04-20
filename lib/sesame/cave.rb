# frozen_string_literal: true

require 'tmpdir'
require 'securerandom'
require 'bases'
require 'digest/crc16'
require 'rbnacl/libsodium'
require 'json'

module Sesame
  # TODO
  class Cave
    attr_accessor :item

    def initialize(path)
      @words = Dict.load
      raise Fail, 'Unexpected dictionary length' unless @words.length == 2048
      @cave = File.expand_path(File.join(path, 'sesame.cave'))
      @lock = File.join(Dir.tmpdir, 'sesame.lock')
      @store = nil
      @dirty = false
      @item = nil
    end

    def path
      @cave
    end

    def exists?
      File.exist?(@cave)
    end

    def locked?
      File.exist?(@lock)
    end

    def open?
      !@store.nil?
    end

    def dirty?
      @dirty
    end

    def create!(phrase)
      raise Fail, 'Cannot create; store already exists' if exists? || locked? || open?
      @store = {}
      insert('sesame', 'cave')
      @dirty = true
      # generate an 88-bit random number as a hex string
      number =
        if phrase.nil?
          RbNaCl::Util.bin2hex(RbNaCl::Random.random_bytes(11))
        else
          words = phrase.downcase.split(' ')
          raise Fail, 'There must be exactly eight words' unless words.length == 8
          raise Fail, 'Unrecognised word used' unless words.all? { |word| @words.include?(word) }
          Bases.val(words).in_base(@words).to_base(16)
        end
      @secret = _create_secret(number)
      # convert the hex string to a word string (base 2048)
      words = Bases.val(number).in_base(16).to_base(@words, array: true)
      # make sure it's always 8 words long (i.e. zero-pad the phrase)
      words.unshift(@words[0]) while words.length < 8
      # sanity check the conversion
      raise Fail, 'Base conversion failure' unless Bases.val(words).in_base(@words).to_base(16) == number.to_s
      # return the phrase to the user
      words.join(' ')
    rescue RbNaCl::CryptoError => e
      raise Fail, e.message
    end

    def open(phrase)
      raise Fail, 'Cannot open store' if !exists? || locked? || open?
      # make sure the phrase is 8 words long and that the words are valid
      words = phrase.downcase.split(' ')
      raise Fail, 'There must be exactly eight words' unless words.length == 8
      raise Fail, 'Unrecognised word used' unless words.all? { |word| @words.include?(word) }
      # convert the phrase to a hex string
      number = Bases.val(words).in_base(@words).to_base(16)
      @secret = _create_secret(number)
      # load the store and decrypt it
      box = RbNaCl::SimpleBox.from_secret_key(@secret)
      encrypted_data = File.open(@cave, 'rb', &:read)
      data = box.decrypt(encrypted_data)
      @store = JSON.parse(data)
      @dirty = false
    rescue RbNaCl::CryptoError => e
      raise Fail, e.message
    end

    def close
      raise Fail, 'Cannot close store; it\'s not open' unless open?
      return unless dirty?
      # encrypt and save the store
      box = RbNaCl::SimpleBox.from_secret_key(@secret)
      data = @store.to_json
      encrypted_data = box.encrypt(data)
      File.open(@cave, 'wb') { |file| file.write(encrypted_data) }
    rescue RbNaCl::CryptoError => e
      raise Fail, e.messsage
    ensure
      @store = nil
      @secret = nil
    end

    def lock
      raise Fail, 'Cannot lock cave; it\'s not open' unless open?
      # create a 16-bit checksum of the secret key
      item = _find('sesame', 'cave')
      data = @secret + item[:index].to_s
      checksum = Digest::CRC16.checksum(data).to_s(16)
      # convert it to a short sequence of short words
      words = Bases.val(checksum).in_base(16).to_base((0...16).to_a, array: true)
      words.map! { |num, _| @words[num.to_i] }
      words.unshift(@words[0]) while words.length < 4
      # create a key from it
      key = _create_secret(checksum)
      # encrypt and save the secret
      box = RbNaCl::SimpleBox.from_secret_key(key)
      encrypted_data = box.encrypt(@secret)
      File.open(@lock, 'wb') { |file| file.write(encrypted_data) }
      # return the phrase to the user
      words.join(' ')
    rescue RbNaCl::CryptoError => e
      raise Fail, e.messsage
    ensure
      @item = nil
      close
    end

    def unlock(phrase)
      raise Fail, 'Cannot unlock store; it\'s not locked' unless locked?
      raise Fail, 'Cannot unlock store; it\'s already open' if open?
      # make sure the phrase is 4 words long and that the words are valid
      words = phrase.downcase.split(' ')
      if words.length == 1 && phrase.length == 4
        words = []
        phrase.each_char do |char|
          words << @words[0..15].find { |word| word[0] == char }
        end
      end
      raise Fail, 'There must be exactly four words' unless words.length == 4
      raise Fail, 'Unrecognised word used' unless words.all? { |word| @words[0..15].include?(word) }
      # convert the phrase to a hex string
      words.map! { |word, _| @words.index(word) }
      checksum = Bases.val(words).in_base((0...16).to_a).to_base(16)
      key = _create_secret(checksum)
      # load the secret and decrypt it
      box = RbNaCl::SimpleBox.from_secret_key(key)
      encrypted_data = File.open(@lock, 'rb', &:read)
      @secret = box.decrypt(encrypted_data)
      # load the store and decrypt it
      box = RbNaCl::SimpleBox.from_secret_key(@secret)
      encrypted_data = File.open(@cave, 'rb', &:read)
      data = box.decrypt(encrypted_data)
      @store = JSON.parse(data)
      item = _find('sesame', 'cave')
      data = @secret + item[:index].to_s
      raise 'Checksum failure' unless Digest::CRC16.checksum(data).to_s(16) == checksum
      @dirty = false
    rescue RbNaCl::CryptoError => e
      raise Fail, e.message
    ensure
      @item = nil
    end

    def forget
      File.delete(@lock)
    end

    def index
      raise Fail, 'Cannot list the store; it\'s not open' unless open?
      @store
    end

    def unique?(service)
      raise Fail, 'Cannot test service uniqueness; store not open' unless open?
      return if @store[service].nil?
      @store[service].count < 2
    end

    def get(service, user, index = nil)
      raise Fail, 'Cannot get service details; store not open' unless open?
      raise Fail, 'Cannot get the sesame service' if service.casecmp('sesame')
      item = _find(service, user)
      item[:index] = index unless index.nil?
      _generate_phrase(item)
    end

    def insert(service, user, index = nil)
      raise Fail, 'Cannot insert service details; store not open' unless open?
      if @store.length.positive?
        raise Fail, 'Cannot insert the sesame service' if service.casecmp('sesame')
      end
      raise Fail, 'Service cannot be empty' if service.strip.length.zero?
      raise Fail, 'User cannot be empty' if user.strip.length.zero?
      item = _find(service, user)
      raise Fail, 'Service and/or user already exists' unless item.nil?
      @store[service] ||= {}
      @store[service][user] = index || 0
      @dirty = true
      return if service == 'sesame'
      item = _find(service, user)
      _generate_phrase(item)
    end

    def update(service, user, index = nil)
      raise Fail, 'Cannot update service details; store not open' unless open?
      item = _find(service, user)
      raise Fail, 'Unable to find that service and/or user' unless item.nil?
      index = item[:index] + 1 if index.nil?
      index = 0 if index.negative?
      user = item[:user]
      @store[service][user] = index
      @dirty = true
      item = _find(service, user)
      _generate_phrase(item) unless service == 'sesame'
    end

    def delete(service, user)
      raise Fail, 'Cannot delete service details; store not open' unless open?
      raise Fail, 'Cannot delete the sesame service' if service.casecmp('sesame')
      item = _find(service, user)
      raise Fail, 'Unable to find that service and/or user' unless item.nil?
      user = item[:user]
      @store[service].delete(user)
      @store.delete(service) if @store[service].count.zero?
      @dirty = true
      _generate_phrase(item)
    end

    protected

    def _create_secret(number)
      mem = 2**30
      ops = mem / 32
      # salt is blank so we always get the same result
      salt = RbNaCl::Util.zeros(RbNaCl::PasswordHash::SCrypt::SALTBYTES)
      RbNaCl::PasswordHash.scrypt(number, salt, ops, mem, RbNaCl::SecretBox.key_bytes)
    rescue RbNaCl::CryptoError => e
      raise Fail, e.message
    end

    def _find(service, user)
      return nil if service.nil? || @store[service].nil?
      @item =
        if user.nil?
          item = @store[service].first
          {
            service: service,
            user: item.first,
            index: item.last
          }
        elsif @store[service][user].nil?
          nil
        else
          index = @store[service][user]
          {
            service: service,
            user: user,
            index: index
          }
        end
    end

    def _generate_phrase(item)
      raise Fail, 'Empty item when generating phrase' if item.nil?
      mem = 2**20
      ops = mem / 32
      raise Fail, 'Cannot generate a phrase; byte count mismatch' unless RbNaCl::PasswordHash::SCrypt::SALTBYTES == @secret.length
      hash = RbNaCl::PasswordHash.scrypt(item.to_json, @secret, ops, mem, 44)
      bits = hash.bytes.map { |byte| byte % 2 }
      words = Bases.val(bits).in_base(2).to_base(@words, array: true)
      words.unshift(@words[0]) while words.length < 4
      words.join(' ')
    rescue RbNaCl::CryptoError => e
      raise Fail, e.message
    end
  end
end
