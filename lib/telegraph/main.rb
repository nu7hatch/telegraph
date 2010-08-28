require 'telegraph/base'
require 'telegraph/delegator'

module Telegraph
  class Application < Base
    set :app_file, $0
    set :run, Proc.new { $0 == config.app_file }

    if run? && ARGV.any?
      options do
        on('-e', '--env [ENVIRONMENT]') {|val| set :environment, val.to_sym }
        on('-p', '--port [PORT]') {|val| set :port, val.to_i }
        on('-h', '--host [HOST]') {|val| set :host, val }
        on('-d', '--debug') {|val| set :debug, true }
      end
      
      Logging.appenders.stdout(
        :level  => config.debug ? :debug : (config.environment.to_s == "production" ? :error : :info),
        :layout => Logging.layouts.pattern(:pattern => "\e[33m[%d]\e[0m %-5l: %m\n")
      )
      
      logger.add_appenders 'stdout'
    end
  end # Application

  at_exit { Application.options.parse!(ARGV.dup) and Application.run! if $!.nil? && Application.run? }
end # Telegraph

include Telegraph::Delegator
