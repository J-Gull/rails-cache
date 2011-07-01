begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  begin
    require 'rubygems'
    require 'bundler'
    Bundler.require
  rescue
    require File.expand_path('../config/environment', __FILE__)
  end
end

begin
  require 'rake/testtask'
  require 'rake/rdoctask'
  require 'spec/rake/spectask'
rescue MissingSourceFile
  STDERR.puts "Error, could not load rake/rspec tasks! (#{$!})\n\nDid you run `bundle install`?\n\n"
  exit 1
end

jt = Jeweler::Tasks.new do |gem|
  gem.name = "ngmoco-cache-money"
  gem.summary = "Write-through and Read-through Cacheing for ActiveRecord"
  gem.description = "Write-through and Read-through Cacheing for ActiveRecord"
  gem.email = "teamplatform@ngmoco.com"
  gem.homepage = "http://github.com/ngmoco/cache-money"
  gem.authors = ["Nick Kallen","Ashley Martens","Scott Mace","John Markos"]
  gem.has_rdoc = false
  gem.files    = FileList[
    "README",
    "TODO",
    "UNSUPPORTED_FEATURES",
    "lib/**/*.rb",
    "rails/init.rb",
    "init.rb"
  ]
  gem.test_files = FileList[
    "config/*",
    "db/schema.rb",
    "spec/**/*.rb"
  ]
  gem.add_dependency("activerecord", [">= 2.2.0"])
  gem.add_dependency("activesupport", [">= 2.2.0"])
end
Jeweler::GemcutterTasks.new

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--format', 'profile', '--color']
end

Spec::Rake::SpecTask.new(:coverage) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['-x', 'spec,gems']
end

desc "Default task is to run specs"
task :default => :spec

namespace :britt do
  desc 'Removes trailing whitespace'
  task :space do
    sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
  end
end


desc "Push a new version to Gemcutter"
task :publish => [ :spec, :build ] do
  system "git tag v#{jt.jeweler.version}"
  system "git push origin v#{jt.jeweler.version}"
  system "git push origin master"
  system "gem push pkg/ngmoco-cache-money-#{jt.jeweler.version}.gem"
  system "git clean -fd"
end
