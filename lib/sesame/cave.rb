# frozen_string_literal: true

require 'tmpdir'
require 'securerandom'
require 'bases'
require 'digest/crc16'
require 'rbnacl/libsodium'
require 'json'

module Sesame
  # The Cave class implements a simple password manager.
  class Cave
    attr_accessor :item

    # Initialize with the path where the cave file will be stored. Optionally
    # specify the complexity of passphrase generation (only change this to lower
    # values to make tests run more quickly).
    def initialize(path, pow = 30)
      @words = Dict.load
      raise Fail, 'Unexpected dictionary length' unless @words.length == 2048
      @cave = File.expand_path(File.join(path, 'sesame.cave'))
      @lock = File.join(Dir.tmpdir, 'sesame.lock')
      @store = nil
      @dirty = false
      @item = nil
      @pow = pow
    end

    # Return the full path of the cave file.
    def path
      @cave
    end

    # True if the cave file exists; false otherwise.
    def exists?
      File.exist?(@cave)
    end

    # True if the lock file exists; false otherwise.
    def locked?
      File.exist?(@lock)
    end

    # True if the cave file has been loaded into memory and decrypted.
    def open?
      !@store.nil?
    end

    # True if the cave has been modified and needs to be persisted.
    def dirty?
      @dirty
    end

    # Create a new cave. If the optional phrase is not supplied, then a random
    # phrase will be returned (this is preferable; users should not select their
    # own passphrase, because humans can't random).
    def create!(phrase = nil)
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
      number.prepend('0') while number.length < 22
      @secret = _create_secret(number)
      # convert the hex string to a word string (base 2048)
      words = Bases.val(number).in_base(16).to_base(@words, array: true)
      # make sure it's always 8 words long (i.e. zero-pad the phrase)
      words.unshift(@words[0]) while words.length < 8
      # sanity check the conversion
      sanity = Bases.val(words).in_base(@words).to_base(16)
      sanity.prepend('0') while sanity.length < 22
      raise Fail, 'Base conversion failure' unless sanity == number
      # return the phrase to the user
      words.join(' ')
    rescue RbNaCl::CryptoError => e
      raise Fail, e.message
    end

    # Open an existing cave, using the supplied phrase to decrypt its contents.
    def open(phrase)
      raise Fail, 'Cannot open store' if !exists? || locked? || open?
      # make sure the phrase is 8 words long and that the words are valid
      words = phrase.downcase.split(' ')
      raise Fail, 'There must be exactly eight words' unless words.length == 8
      raise Fail, 'Unrecognised word used' unless words.all? { |word| @words.include?(word) }
      # convert the phrase to a hex string
      number = Bases.val(words).in_base(@words).to_base(16)
      number.prepend('0') while number.length < 22
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

    # Close the cave, encrypting and saving its contents if dirty.
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
      @item = nil
      @store = nil
      @secret = nil
      @dirty = false
    end

    # Lock the cave by encrypting and saving the secret to a lock file, and then
    # closing the cave (which may mean saving it, if it was dirty).
    def lock
      raise Fail, 'Cannot lock cave; it\'s not open' unless open?
      # create a 16-bit checksum of the secret key
      item = _find('sesame', 'cave')
      data = @secret.dup
      data << item[:index]
      checksum = Digest::CRC16.checksum(data).to_s(16)
      checksum.prepend('0') while checksum.length < 4
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
      close
    end

    # Unlock the cave, by loading and decrypting the secret using the supplied
    # phrase, and then using that to load and decrypt the cave itself.
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
      checksum.prepend('0') while checksum.length < 4
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
      data = @secret.dup
      data << item[:index]
      sanity = Digest::CRC16.checksum(data).to_s(16)
      sanity.prepend('0') while sanity.length < 4
      raise 'Checksum failure' unless sanity == checksum
      @dirty = false
    rescue RbNaCl::CryptoError => e
      raise Fail, e.message
    ensure
      @item = nil
      forget if locked?
    end

    # Remove the lock file.
    def forget
      File.delete(@lock)
    end

    # Return the store. Note that this doesn't expose any super-sensitive data;
    # the store is just a hash of service name, usernames for each service, and
    # a nonce for each username. These are combined with the secret (which is
    # itself derived from the users passphrase) to create the password for each
    # service and username.
    def index
      raise Fail, 'Cannot list the store; it\'s not open' unless open?
      @store.sort.to_h
    end

    # True if a particular service has exactly one username.
    def unique?(service)
      raise Fail, 'Cannot test service uniqueness; store not open' unless open?
      raise Fail, 'No such service' if @store[service].nil?
      @store[service].count < 2
    end

    # Generate and return the passphrase for a service and username.
    def get(service, user = nil, index = nil)
      raise Fail, 'Cannot get service details; store not open' unless open?
      raise Fail, 'Cannot get the sesame service' if service.casecmp('sesame').zero?
      item = _find(service, user)
      item[:index] = index unless index.nil?
      _generate_phrase(item)
    end

    # Insert a new service and username, then generate and return the passphrase.
    def insert(service, user, index = nil)
      raise Fail, 'Cannot insert service details; store not open' unless open?
      if @store.length.positive?
        raise Fail, 'Cannot insert the sesame service' if service.casecmp('sesame').zero?
      end
      raise Fail, 'Service cannot be empty' if service.strip.length.zero?
      raise Fail, 'User cannot be empty' if user.nil? || user.strip.length.zero?
      raise Fail, 'User already exists for that service' unless @store[service].nil? || @store[service][user].nil?
      @store[service] ||= {}
      @store[service][user] = index || 0
      @dirty = true
      return if service == 'sesame'
      item = _find(service, user)
      _generate_phrase(item)
    end

    # Update the nonce for a service and username, then generate and return the
    # passphrase.
    def update(service, user = nil, index = nil)
      raise Fail, 'Cannot update service details; store not open' unless open?
      item = _find(service, user)
      index = item[:index] + 1 if index.nil?
      index = 0 if index.negative?
      user = item[:user]
      @store[service][user] = index
      @dirty = true
      item = _find(service, user)
      _generate_phrase(item) unless service == 'sesame'
    end

    # Remove a service and username, then generate and return the passphrase.
    def delete(service, user = nil)
      raise Fail, 'Cannot delete service details; store not open' unless open?
      raise Fail, 'Cannot delete the sesame service' if service.casecmp('sesame').zero?
      item = _find(service, user)
      user = item[:user]
      @store[service].delete(user)
      @store.delete(service) if @store[service].count.zero?
      @dirty = true
      _generate_phrase(item)
    end

    protected

    def _create_secret(number)
      mem = 2**@pow
      ops = mem / 32
      # salt is blank so we always get the same result
      salt = RbNaCl::Util.zeros(RbNaCl::PasswordHash::SCrypt::SALTBYTES)
      RbNaCl::PasswordHash.scrypt(number, salt, ops, mem, RbNaCl::SecretBox.key_bytes)
    rescue RbNaCl::CryptoError => e
      raise Fail, e.message
    end

    def _find(service, user)
      raise Fail, 'No such service' if service.nil? || @store[service].nil?
      @item =
        if user.nil?
          raise Fail, 'No unique user for service' unless unique?(service)
          item = @store[service].first
          {
            service: service,
            user: item.first,
            index: item.last
          }
        elsif @store[service][user].nil?
          raise Fail, 'No such service or user'
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
