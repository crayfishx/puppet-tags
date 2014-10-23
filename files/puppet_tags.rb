#!/usr/bin/ruby

require 'fileutils'
require 'yaml'
require 'rubygems'

options = {
  :gitrepo          => nil,
  :cachedir         => '/var/puppet_environment/src',
  :releasedir       => '/var/puppet_environment/release',
  :gitcmd           => '/usr/bin/git',
  :minversion       => '0.0.1',
  :environmentpath  => '/etc/puppet/environments'
}

if File.exists?("/etc/puppet_tags.yaml")
  configoptions = YAML.load_file("/etc/puppet_tags.yaml")
  options.merge!(configoptions)
end

options.keys.each do |o|
  unless options[o]
    puts "Must supply #{o}. aborting."
    exit 1
  end
end


unless File.directory?(options[:cachedir])
  FileUtils.mkdir_p(options[:cachedir])
end



unless File.directory?("#{options[:cachedir]}/.git")
  %x{ #{options[:gitcmd]} clone #{options[:gitrepo]} #{options[:cachedir]} }
end

Dir.chdir(options[:cachedir]) do

  %x{ #{options[:gitcmd]} fetch }
  %x{ #{options[:gitcmd]} tag -l }.split(/\n+/).each do |tag|

    # Skip over any tags that are malformed or are less than the minimum version
    begin
      next unless Gem::Version.new(tag) >= Gem::Version.new(options[:minversion])
    rescue ArgumentError => e
      next
    end

    # We can't have dots in Puppet environments
    env=tag.gsub(/\./,"_")

    unless File.exists?("#{options[:environmentpath]}/#{env}")
      puts "Deploying #{tag} to #{options[:environmentpath]}/#{env}"

      FileUtils.mkdir_p("#{options[:environmentpath]}/#{env}")
      %x{ #{options[:gitcmd]} archive --format=tar #{tag} | ( cd #{options[:environmentpath]}/#{env} && tar -xf -) }

      Dir.chdir("#{options[:environmentpath]}/#{env}") do
        %x{ r10k puppetfile install }
      end
    end
  end
end
