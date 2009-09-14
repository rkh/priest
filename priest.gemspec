Gem::Specification.new do |s|
  s.name              = "priest"
  s.version           = "0.0.7"
  s.summary           = "Priest, the command line tool for monk."
  s.description       = "Priest is a more advanced replacement for the monk command line tool. Monk is a glue framework for web development. It means that instead of installing all the tools you need for your projects, you can rely on a git repository and a list of dependencies, and Monk will care of the rest. By default, it ships with a Sinatra application that includes Contest, Stories, Webrat, Ohm and some other niceties, along with a structure and helpful documentation to get your hands wet in no time."
  s.authors           = ["Konstantin Haase"]
  s.email             = ["konstantin.mailinglists@googlemail.com"]
  s.homepage          = "http://github.com/rkh/priest"

#  s.rubyforge_project = "monk"

  s.executables << "priest"

  s.add_dependency("thor", "~> 0.11")
  s.add_dependency("dependencies", ">= 0.0.7")
  s.requirements << "git"

  s.files = ["LICENSE", "README.markdown", "Rakefile", "bin/priest", "lib/monk/skeleton.rb", "lib/monk.rb", "priest.gemspec", "test/commands.rb", "test/integration_test.rb", "test/monk_test.rb", "test/test_helper.rb"]
end
