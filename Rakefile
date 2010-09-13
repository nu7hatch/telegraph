require 'rubygems'
require 'rake'

require File.dirname(__FILE__) + '/lib/telegraph/version'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version = Telegraph::VERSION
    gem.name = "telegraph"
    gem.summary = %Q{Telegraph is DSL for quickly creating TCP servers in Ruby.}
    gem.description = <<-DESCR
      Telegraph is DSL for quickly creating TCP servers in Ruby. It's running on  
      EventMachine and is similar to Sinatra web framework.
    DESCR
    gem.email = "kriss.kowalik@gmail.com"
    gem.homepage = "http://github.com/nu7hatch/telegraph"
    gem.authors = ["Kriss 'nu7hatch' Kowalik"]
    gem.add_development_dependency "riot", ">= 0.11.3"
    gem.add_dependency "eventmachine", ">= 0.12.8"
    gem.add_dependency "logging", ">= 1.4.3"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = Telegraph::VERSION
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "telegraph #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
