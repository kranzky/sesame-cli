require 'highline/import'
require 'json'
require 'i18n'
require 'clipboard'

module Sesame
  class Jinn
    def initialize(opts)
      @opts = opts
      _parse
      _welcome
      @sesame = Cave.new(@opts[:path])
      I18n.load_path = Dir[File.join(File.dirname(__FILE__), 'lang', '*yml')]
    rescue Fail => e
      _error(e.message)
    end

    def process!
      was_locked = false
      if @sesame.exists?
        @sesame.forget if @sesame.locked? && @opts.expunge?
        if @sesame.locked?
          _unlock
          @sesame.forget
          was_locked = true
        else
          _open
        end
      else
        @sesame.forget if @sesame.locked?
        _new
      end
      _process(@opts[:command])
      if @opts[:command].nil? || @opts.interactive?
        loop do
          say("\n")
          break if _prompt
        end
        if @opts.expunge?
          @sesame.close
        else
          _lock(was_locked)
        end
      elsif was_locked
        _lock(true)
      else
        @sesame.close
      end
    rescue Fail => e
      _error(e.message)
    end

    protected

    def _welcome
      return if @opts[:quiet]
      say(HighLine.color(<<~EOS, :bold, :yellow))
        ╔═════════════════════════════════════╗
        ║ ┏━━━┓ ┏━━━┓ ┏━━━┓  ┏━┓  ┏┓ ┏┓ ┏━━━┓ ║
        ║ ┗━╋━┓ ┣━━┫  ┗━╋━┓ ┏┻━┻┓ ┃┗┳┛┃ ┣━━┫  ║
        ║ ┗━━━┛ ┗━━━┛ ┗━━━┛ ┗   ┛ ┗   ┛ ┗━━━┛ ║
        ╚═════════════════════════════════════╝
      EOS
    end

    def _parse
      _set_path
      _set_command('list') if @opts.list?
      _set_command('add') if @opts.add?
      _set_command('get') if @opts.get?
      _set_command('next') if @opts.next?
      _set_command('delete') if @opts.delete?
    end

    def _set_path
      # set @opts[:path] if nil from .sesamerc and then $SESAME_PATH and then current dir
      if @opts[:path].nil?
        @opts[:path] = _load_config || ENV.fetch('SESAME_PATH', '.')
      end
      @opts[:path] = File.expand_path(@opts[:path])
      unless Dir.exist?(@opts[:path])
        say("No such directory: #{@opts[:path]}")
        exit 2
      end
    end

    def _load_config(base=".")
      path = File.join(base, '.sesamerc')
      if File.exist?(path)
        File.read(path)
      elsif base == '.'
        _load_config(Dir.home)
      end
    end

    def _set_command(name)
      if @opts[:command].nil?
        @opts[:command] = name
      else
        say("Cannot execute command #{name}; #{@opts[:command]} already specified!")
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
        _error
      end
    end

    def _prompt
      done = false
      _info("prompt")
      choose do |menu|
        menu.prompt = "\n> "
        menu.shell = true
        menu.choice(:list, "Display all of the services and users in your Sesame store.") do |command, args|
          _set_opts(args)
          _list
        end
        menu.choice(:add, "Add a new service and user to your Sesame store.") do |command, args|
          _set_opts(args)
          _add
        end
        menu.choice(:get, "Retrieve the pass phrase for a service and user.") do |command, args|
          _set_opts(args)
          _get
        end
        menu.choice(:next, "Generate a new passphrase for a service and user.") do |comnmand, args|
          _set_opts(args)
          _next
        end
        menu.choice(:delete, "Remove a service and user from the Sesame store.") do |command, args|
          _set_opts(args)
          _delete
        end
        menu.choice(:exit, "Close Sesame.") do
          done = true
        end
      end
      done
    rescue Fail => e
      _error(e.message)
    end

    def _error(details="An error occurred")
      message =
        if @opts[:quiet]
          _trans("error", details: details)
        else
          _trans("jinn.error", details: details)
        end
      say(HighLine.color(message, :bold, :red))
    end

    def _new
      words = nil
      if @opts.reconstruct?
        _info("reconstruct")
        words = ask("🔑  ") { |q| q.echo = "*" }
      end
      phrase = @sesame.create!(words)
      if words.nil?
        _info("new")
        _show(phrase)
      else
        _info("reconstructed")
      end
    end

    def _open
      _info("open")
      words = ask("🔑  ") { |q| q.echo = "*" }
      @sesame.open(words)
      _info("path", path: @sesame.path)
    end

    def _unlock
      _info("unlock")
      key = ask("🔑  ") { |q| q.echo = "*" }
      @sesame.unlock(key)
      _info("path", path: @sesame.path)
    end

    def _forget
      _info("forgot")
      @sesame.forget
    end

    def _list
      _info("list")
      if @opts[:service].nil? || @opts[:service].length == 0
        @sesame.index.each do |service, users|
          next if service == 'sesame'
          if users.count > 1
            say("#{service} (#{users.count})")
          else
            say(service)
          end
        end
      else
        users = @sesame.index[@opts[:service]]
        raise Fail, "No such service found, you must be thinking of some other cave" if users.nil? || @opts[:service] == "sesame"
        users.each do |user, index|
          say(user)
        end
      end
    end

    def _get
      phrase = @sesame.get(*_question, @opts[:offset])
      _info("get", @sesame.item)
      _show(phrase)
    end

    def _add
      phrase = @sesame.insert(*_question(true), @opts[:offset])
      _info("add", @sesame.item)
      _show(phrase)
    end

    def _next
      phrase = @sesame.update(*_question, @opts[:offset])
      if phrase.nil?
        _info("next_key")
      else
        _info("next", @sesame.item)
        _show(phrase)
      end
    end

    def _delete
      phrase = @sesame.delete(*_question)
      _info("delete")
      _show(phrase)
    end

    def _lock(silent=false)
      key = @sesame.lock
      return if silent
      _info("lock")
      _show(key)
    end

    def _info(message, args={})
      message =
        if @opts[:quiet]
          _trans(message, args)
        else
          _trans("jinn.#{message}", args)
        end
      return if message.nil? || message.length == 0
      say(HighLine.color(message, :bold, :green))
    end

    def _trans(message, args)
      retval = I18n.t(message, args)
      if retval =~ /^translation missing/
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

    def _set_opts(args)
      args = args.split(" ").map(&:strip).map(&:downcase)
      return if args.count == 0
      @opts[:service] = args.first if args.count < 3
      @opts[:user] = args.last if args.count == 2
    end

    def _question(user_required=false)
      service, user = @opts[:service], @opts[:user]
      if service.nil?
        _info("service")
        service = ask("🏷  ")
      end
      if user.nil? && (user_required || !@sesame.unique?(service))
        _info("user")
        user = ask("👤  ")
      end
      [service.downcase, user.nil? ? nil : user.downcase]
    end
  end
end
