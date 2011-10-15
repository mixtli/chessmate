module Chess
  module Client
    class Base
      def initialize(opts = {})
        puts opts.inspect
        @options = opts
        @options[:server] ||= 'fics.freechess.org'
        @options[:port] ||= 5000
        @callback_object = @options[:callback_object]
        @mode = :normal

        @logfile = File.open("#{opts[:log_file]}", "a")
      end
    end
  end
end

