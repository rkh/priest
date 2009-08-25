#! /usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "thor"
require "yaml"

require "monk/skeleton"

class Monk < Thor
  include Thor::Actions
  
  class_options[:skip].aliases.delete "-s"
  
  def self.git_option(name, options = {})
    class_option name, options.merge(:group => :git)
    git_options << name.to_s
  end
    
  def self.git_options
    @git_options ||= ["mirror_path"]
  end
  
  def self.monk_home
    ENV["MONK_HOME"] || File.join(Thor::Util.user_home)
  end
  
  def self.monk_mirrors
    File.join(monk_home, ".monk_mirrors")
  end
  
  git_option :branch, :type => :string, :aliases => "-b",
             :desc => "Specify skeleton branch to use."
  git_option :keep_remote, :type => :boolean, :aliases => "-k",
             :desc => "Do not remove .git folder and keep skeleton as remote"
  git_option :remote_name, :type => :string, :aliases => "-r",
             :desc => "Remote name to use for the skeleton. Default is skeleton"
  git_option :mirror, :type => :boolean, :aliases => "-m",
             :desc => "Keep local mirror of the skeleton. For offline use and frequent project creation"
  
  desc "init", "Initialize a Monk application. Will try to update mirror for given skeleton."
  method_option :skeleton, :type => :string, :aliases => "-s"     
  def init(target = ".")
    say_status :fetching, skeleton.url
    skeleton.create(target) ?
      say_status(:initialized, target) :
      say_status(:error, clone_error(target))
  end
  
  desc "show NAME", "Display the repository address for NAME"
  def show(name)
    say_status name, monk_config[name] ? skeleton(name).description : "repository not found"
  end

  desc "list", "Lists the configured repositories"
  def list
    monk_config.keys.sort.each { |key| show(key) }
  end

  desc "add NAME REPOSITORY_URL", "Add the repository to the configuration file"
  def add(name, repository_url)
    monk_config[name] = Skeleton.new(repository_url)
    monk_config[name].merge! git_options
    write_monk_config_file
    say_status :added, name
  end

   desc "change NAME", "Modifies options for a repository without having to repeat the url"
   def change(name)
     if monk_config.include? name
       monk_config[name].merge! git_options
       path = monk_config[to].delete "mirror_path"
       system "rm -R #{path}" if path
       write_monk_config_file
       say_status :modified, name
     else
       say_status name, "repository not found"
     end
   end

   desc "rm NAME", "Remove the repository from the configuration file"
   def rm(name)
     skel = monk_config.delete(name)
     write_monk_config_file
     system "rm -R #{skel.mirror_path}" if skel.mirror_path?
     say_status :deleted, name
   end

   desc "copy FROM TO", "Creates a copy of an existing skeleton"
   def copy(from, to)
     return unless monk_config.include? from
     monk_config[to] = skeleton(from)
     monk_config[to].delete "mirror_path"
     write_monk_config_file
     say_status :added, to
   end
   
   desc "cleanup", "Removes mirrors no longer used (or all mirrors with --all)"
   method_option :all, :type => :boolean, :aliases => "-a"
   def cleanup
     say_status "scanning", "mirrors"
     mirrors = Dir.glob File.join(Monk.monk_mirrors, "*")
     monk_config.each_value do |skel|
       mirrors.delete skel.mirror_path if skel.mirror_path?
     end unless options["all"]
     say_status "cleanup", "mirrors"
     system "rm -R #{mirrors.join " "}"
   end
   
   desc "update", "Updates all mirrors or mirrors for given skeleton."
   def update(name = nil)
     name ||= options[:skeleton]
     return monk_config.each_key { |s| update(s) } unless name
     skel = skeleton(name)
     if skel.mirror?
       say_status "update", name
       skel.update_mirror
     end
   end
  

private

  def skeleton(name = nil)
    name ||= options[:skeleton] || "default"
    (monk_config[name] || Skeleton.new(name)).merge git_options
  end
  
  def git_options
    self.class.git_options.inject({}) do |opts, key|
       opts.merge key => options[key] if options.include? key
       opts
    end
  end

  def monk_config_file
    @monk_config_file ||= File.join(monk_home, ".monk")
  end

  def monk_config
    @monk_config ||= begin
      write_monk_config_file unless File.exists? monk_config_file
      YAML.load_file(monk_config_file).inject({}) do |config, (key, value)|
        config.merge key => Skeleton.new(value)
      end
    end
  end

  def write_monk_config_file
    remove_file monk_config_file
    create_file monk_config_file do
      config = @monk_config || { "default" => Skeleton.new("git://github.com/monkrb/skeleton.git") }
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
    self.class.monk_home
  end
end