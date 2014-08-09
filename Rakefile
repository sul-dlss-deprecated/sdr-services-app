require 'rspec/core/rake_task'

task :default => :spec

desc 'Run specs'
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end

desc 'Run IRB console with app environment'
task :console do
  puts 'Loading development console...'
  system('irb -r ./config/boot.rb')
end

desc 'Generate API docs'
task :doc do
  puts 'Generating API documentation, using YARD.'
  system('bundle exec yardoc -q') # see .yardopts
end

desc 'Show help menu'
task :help do
  puts 'Available rake tasks: '
  puts 'rake console - Run a IRB console with all environment loaded'
  puts 'rake spec - Run specs and calculate coverage'
  puts 'rake doc - Generate API documentation, using YARD.'
end

