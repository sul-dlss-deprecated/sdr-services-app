require 'rspec/core/rake_task'

task :default => :spec

#require 'dotenv/tasks'
#task :mytask => :dotenv do
#  # things that require .env
#end

desc 'Run specs'
task :spec do
  ENV['APP_ENV'] = 'test'
  ENV['RACK_ENV'] = 'test'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end

desc 'Run IRB console with app environment'
task :console do
  puts 'Running ./bin/console'
  system('./bin/console')
end

desc 'Generate API docs'
task :doc do
  puts 'Generating API documentation, using YARD.'
  system('.binstubs/yardoc') # see .yardopts
end

desc 'Show help menu'
task :help do
  puts 'Available rake tasks: '
  puts 'rake console - Run a IRB console with all environment loaded'
  puts 'rake doc - Generate API documentation, using YARD.'
  puts 'rake spec - Run specs and calculate coverage'
end

