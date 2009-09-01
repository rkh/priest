#require "rubygems"
require "contest"
require "hpricot"
require "fileutils"

ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

$:.unshift ROOT

require "test/commands"

class Test::Unit::TestCase
  include Test::Commands
  include FileUtils

  def root(*args)
    File.expand_path File.join(ROOT, *args)
  end
  
  def tmp_path(*args)
    root("test", "tmp", *args)
  end

  def setup
    mkdir_p tmp_path
    rm_f tmp_path(".monk")
    create_template "default"
  end
  
  def template_path(name = default)
    tmp_path("templates", name)
  end
  
  def create_template(name, add = "")
    dir = template_path(name)
    mkdir_p dir
    chdir(dir) do
      unless File.exist? "name"
        File.open("name", "w") { |f| f << name }
        raise RuntimeError, "could not initialize git repo" unless system <<-EOS
          git init -q  &&
          git add name 2>/dev/null &&
          git ci -m "created template" -q
        EOS
      end
    end
    monk("add #{name} #{dir} #{add}") if add
    dir
  end
  
  def in_template(name, &block)
    chdir(create_template(name), &block)
  end

  def monk(args = nil)
    sh("env MONK_HOME=#{File.join(ROOT, "test", "tmp")} ruby -rubygems #{root "bin/monk"} #{args}")
  end
end
