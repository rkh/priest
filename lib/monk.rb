#! /usr/bin/env ruby

require "thor"
require "yaml"
require "fileutils"

class Monk < Thor
  include Thor::Actions
  
  class << self    
    private
    
    # options every git aware task takes
    def git_options
      method_option :branch, :type => :string, :alias => "-b"
      method_option :keep_remote, :type => :boolean
      method_option :remote_name, :type => :string
    end
    
  end

  desc "init", "Initialize a Monk application"
  method_option :skeleton, :type => :string, :aliases => "-s"
  git_options     
  def init(target = ".")
    clone(source(options[:skeleton] || "default"), target) ?
      cleanup(target) :
      say_status(:error, clone_error(target))
  end

  desc "show NAME", "Display the repository address for NAME"
  def show(name)
    if monk_config.include? name
      say_status name, *source(name).values_at(:url, :branch)
    else
      say_status name, "repository not found"
    end
  end

  desc "list", "Lists the configured repositories"
  def list
    monk_config.keys.sort.each do |key|
      show(key)
    end
  end

  desc "add NAME REPOSITORY_URL", "Add the repository to the configuration file"
  git_options
  def add(name, repository_url)
    monk_config[name] = { :url => repository_url }
    monk_config[name].merge! options
    write_monk_config_file
  end
  
  desc "change NAME", "Modifies options for a repository without having to repeat the url."
  git_options
  def change(name)
    if monk_config.include? name
      monk_config[name].merge! options
      write_monk_config_file
    else
      say_status name, "repository not found"
    end
  end

  desc "rm NAME", "Remove the repository from the configuration file"
  def rm(name)
    monk_config.delete(name)
    write_monk_config_file
  end
  
  desc "copy FROM TO", "Creates a copy of an existing skeleton."
  git_options
  def copy(from, to)
    return unless monk_config.include? from
    monk_config[to] = monk_config[from].merge options
    write_monk_config_file 
  end

private

  def clone(src, target)
    if Dir["#{target}/*"].empty?
      FileUtils.mkdir_p target
      Dir.chdir(target) do
        say_status :fetching, src[:url]
        branch = src[:branch] || "master"
        remote = src[:remote_name] || "skeleton"
        system <<-EOS
          git init &&
          git remote add -t #{branch} -f #{remote} #{src[:url]} &&
          git checkout -t #{remote}/#{branch}
        EOS
      end
    end
  end

  def cleanup(target)
    inside(target) { remove_file ".git" } unless options.keep_remote?
    say_status :initialized, target
  end

  def source(name)
    monk_config[name]
  end
  

  def monk_config_file
    @monk_config_file ||= File.join(monk_home, ".monk")
  end

  def monk_config
    @monk_config ||= begin
      write_monk_config_file unless File.exists? monk_config_file
      YAML.load_file(monk_config_file).inject({}) do |config, (key, value)|
        # fixing old monk config files
        config.merge key => value.respond_to?(:keys) ? value : {:url => value}
      end
    end
  end

  def write_monk_config_file
    remove_file monk_config_file
    create_file monk_config_file do
      config = @monk_config || { "default" => {:url => "git://github.com/monkrb/skeleton.git"} }
      config.to_yaml
    end
  end

  def self.source_root
    "."
  end

  def clone_error(target)
    "Couldn't clone repository into target directory '#{target}'. " +
    "You must have git installed and the target directory must be empty."
  end

  def monk_home
    ENV["MONK_HOME"] || File.join(Thor::Util.user_home)
  end
end
