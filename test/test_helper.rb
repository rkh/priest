#require "rubygems"
require "contest"
require "hpricot"
require "fileutils"

ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

$:.unshift ROOT

require "test/commands"

class Test::Unit::TestCase
  include Test::Commands

  def root(*args)
    File.join(ROOT, *args)
  end

  def setup
    FileUtils.rm(File.join(ROOT, "test", "tmp", ".monk"))
  end

  def monk(args = nil)
    sh("env MONK_HOME=#{File.join(ROOT, "test", "tmp")} ruby -rubygems #{root "bin/monk"} #{args}")
  end
end
