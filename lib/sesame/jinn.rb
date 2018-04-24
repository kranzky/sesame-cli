# frozen_string_literal: true

require 'highline/import'
require 'i18n'
require 'clipboard'

module Sesame
  # The Jinn class is wholly responsible for interacting with the terminal.
  class Jinn
    # Pass in parsed command-line options as a Slop instance.
    def initialize(opts)
      I18n.load_path = Dir[File.join(File.dirname(__FILE__), 'lang', '*yml')]
      @opts = opts
      _config
      _parse
      _welcome
      @cave = Cave.new(@opts[:path])
    rescue Fail => e
      _error(e.message)
    end

    # Process the users request, possibly starting an interactive session.
    def process!
      return if @cave.nil?
      @was_locked = false
      raise Fail, 'Cannot lock and expunge simultaneously' if @opts.lock? && @opts.expunge?
      if @cave.exists?
        raise Fail, 'Please remove the cave before attempting to reconstruct' if @opts.reconstruct?
        raise Fail, 'Cannot expunge lock; it doesn\'t exist' if @opts.expunge? && !@cave.locked?
        raise Fail, 'Please specify a command (or use interactive mode)' if !@opts.interactive? && @opts[:command].nil? && !@opts.lock? && !@opts.expunge?
        if @cave.locked? && @opts.expunge?
          @cave.forget
          _warn('Lock expunged')
        end
        if @cave.locked?
          _unlock
          @was_locked = true
        else
          _open
        end
      else
        @cave.forget if @cave.locked?
        _new
      end
      _process(@opts[:command])
      if @opts.interactive?
        loop do
          say("\n")
          break if _prompt
        end
        if @opts.expunge?
          @cave.close
        else
          _lock
        end
      elsif @opts.expunge? || (!@was_locked && !@opts.lock?)
        @cave.close
      else
        _lock
      end
    rescue Fail => e
      _error(e.message)
    rescue SystemExit, Interrupt
      _error('Stopped by user')
    end

    protected

    def _welcome
      return if @opts[:quiet]
      say(HighLine.color(<<~WELCOME, :bold, :yellow))
        ╔═════════════════════════════════════╗
        ║ ┏━━━┓ ┏━━━┓ ┏━━━┓  ┏━┓  ┏┓ ┏┓ ┏━━━┓ ║
        ║ ┗━╋━┓ ┣━━┫  ┗━╋━┓ ┏┻━┻┓ ┃┗┳┛┃ ┣━━┫  ║
        ║ ┗━━━┛ ┗━━━┛ ┗━━━┛ ┗   ┛ ┗   ┛ ┗━━━┛ ║
        ╚═════════════════════════════════════╝
      WELCOME
    end

    def _load_config(base = '.', name = '.sesamerc')
      path = File.join(base, name)
      if File.exist?(path)
        JSON.parse(File.read(path), symbolize_names: true)
      elsif name == '.sesamerc'
        _load_config(base, 'sesame.cfg')
      elsif base == '.'
        _load_config(Dir.home)
      else
        {}
      end
    rescue JSON::ParserError
      raise Fail, "#{path} is not valid JSON"
    end

    def _config
      config = _load_config
      _set_opt(:echo, config[:echo]) unless @opts.echo?
      _set_opt(:interactive, config[:interactive]) unless @opts.interactive?
      _set_opt(:quiet, config[:quiet]) unless @opts.quiet?
      config[:path] ||= ENV.fetch('SESAME_PATH', '.')
      _set_opt(:path, config[:path]) if @opts[:path].nil?
      _set_opt(:path, File.expand_path(@opts[:path]))
    end

    def _parse
      unless Dir.exist?(@opts[:path])
        _error("No such directory: #{@opts[:path]}")
        exit 2
      end
      _set_command('list') if @opts.list?
      _set_command('add') if @opts.add?
      _set_command('get') if @opts.get?
      _set_command('next') if @opts.next?
      _set_command('delete') if @opts.delete?
    end

    def _set_command(name)
      if @opts[:command].nil?
        _set_opt(:command, name)
      else
        _error("Cannot #{name} and #{@opts[:command]}")
        exit 2
      end
    end

    def _process(command)
      return if command.nil?
      case command.to_sym
      when :list
        _list
      when :add
        _add
      when :get
        _get
      when :next
        _next
      when :delete
        _delete
      else
        _error('Command not recognised')
      end
    end

    def _prompt
      done = false
      _info('prompt')
      choose do |menu|
        menu.prompt = "\n> "
        menu.shell = true
        menu.choice(:list, 'Display all of the services and users in your Sesame store.') do |_, args|
          _set_opts(args)
          _list
        end
        menu.choice(:add, 'Add a new service and user to your Sesame store.') do |_, args|
          _set_opts(args)
          _add
        end
        menu.choice(:get, 'Retrieve the pass phrase for a service and user.') do |_, args|
          _set_opts(args)
          _get
        end
        menu.choice(:next, 'Generate a new passphrase for a service and user.') do |_, args|
          _set_opts(args)
          _next
        end
        menu.choice(:delete, 'Remove a service and user from the Sesame store.') do |_, args|
          _set_opts(args)
          _delete
        end
        menu.choice(:exit, 'Close Sesame.') do
          done = true
        end
      end
      _clear_opts
      done
    rescue Fail => e
      _error(e.message)
    end

    def _error(details = 'An error occurred')
      message =
        if @opts[:quiet]
          _trans('error', details: details)
        else
          _trans('jinn.error', details: details)
        end
      say(HighLine.color(message, :bold, :red))
    end

    def _warn(details)
      message =
        if @opts[:quiet]
          _trans('warn', details: details)
        else
          _trans('jinn.warn', details: details)
        end
      say(HighLine.color(message, :bold, :yellow))
    end

    def _new
      words = nil
      if @opts.reconstruct?
        _info('reconstruct')
        words = ask('🔑  ') { |q| q.echo = '*' }
      end
      phrase = @cave.create!(words)
      if words.nil?
        _info('new')
        _show(phrase)
      else
        _info('reconstructed')
      end
    end

    def _open
      _info('open')
      words = ask('🔑  ') { |q| q.echo = '*' }
      @cave.open(words)
      _info('path', path: @cave.path)
    end

    def _unlock
      _info('unlock')
      key = ask('🔑  ') { |q| q.echo = '*' }
      @cave.unlock(key)
      _info('path', path: @cave.path)
    end

    def _forget
      _info('forgot')
      @cave.forget
    end

    def _list
      _info('list')
      if @opts[:service].nil? || @opts[:service].length.zero?
        @cave.index.each do |service, users|
          next if service == 'sesame'
          if users.count > 1
            say("#{service} (#{users.count})")
          else
            say("#{service} (#{users.first.first})")
          end
        end
      else
        users = @cave.index[@opts[:service]]
        raise Fail, 'No such service found, you must be thinking of some other cave' if users.nil? || @opts[:service] == 'sesame'
        users.sort.each do |user, _|
          say(user)
        end
      end
    end

    def _get
      phrase = @cave.get(*_question, @opts[:offset])
      _info('get', @cave.item)
      _show(phrase)
    end

    def _add
      phrase = @cave.insert(*_question(true), @opts[:offset])
      _info('add', @cave.item)
      _show(phrase)
    end

    def _next
      phrase = @cave.update(*_question, @opts[:offset])
      if phrase.nil?
        _info('next_key')
        @was_locked = false
        _set_opt(:lock, true)
      else
        _info('next', @cave.item)
        _show(phrase)
      end
    end

    def _delete
      phrase = @cave.delete(*_question)
      _info('delete')
      _show(phrase)
    end

    def _lock
      key = @cave.lock
      return if @was_locked
      _info('lock')
      _show(key)
    end

    def _info(message, args = {})
      message =
        if @opts[:quiet]
          _trans(message, args)
        else
          _trans("jinn.#{message}", args)
        end
      return if message.nil? || message.length.zero?
      say(HighLine.color(message, :bold, :green))
    end

    def _trans(message, args)
      retval = I18n.t(message, args)
      if retval.match?(/^translation missing/)
        retval =
          if @opts[:echo]
            I18n.t("#{message}_echo", args)
          else
            I18n.t("#{message}_clip", args)
          end
      end
      retval
    end

    def _show(data)
      if @opts[:echo]
        say(data)
      else
        Clipboard.copy(data)
      end
    end

    def _set_opt(name, val)
      return unless val
      @opts.option(name).ensure_call(val)
    end

    def _set_opts(args)
      args = args.split(' ').map(&:strip).map(&:downcase)
      return if args.count.zero?
      _set_opt(:service, args.first) if args.count < 3
      _set_opt(:user, args.last) if args.count == 2
    end

    def _clear_opt(name)
      @opts.option(name).reset
    end

    def _clear_opts
      _clear_opt(:service)
      _clear_opt(:user)
    end

    def _question(user_required = false)
      service = @opts[:service]
      user = @opts[:user]
      if service.nil?
        _info('service')
        service = ask('🏷  ')
      end
      if user.nil? && (user_required || !@cave.unique?(service))
        _info('user')
        user = ask('👤  ')
      end
      [service.downcase, user.nil? ? nil : user.downcase]
    end
  end
end
