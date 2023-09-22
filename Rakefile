# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard/doctest/rake'

RSpec::Core::RakeTask.new(:spec)
YARD::Doctest::RakeTask.new

task :default do
  Rake::Task['spec'].invoke
  Rake::Task['yard:doctest'].invoke
end
