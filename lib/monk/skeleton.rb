require 'thor/core_ext/hash_with_indifferent_access'
require 'monk'

class Monk < Thor
  class Skeleton
    
    include Thor::CoreExt    
    attr_accessor :options, :target
    
    DEFAULTS = { "remote_name" => "skeleton", "branch" => "master" }
    
    def initialize(url = nil, opts = {})
      if url.respond_to? :merge
        opts.merge! url
        url = nil
      end
      self.options = HashWithIndifferentAccess.new opts
      options[:url] ||= url
      raise ArgumentError, "no url given" unless options.url?
      options[:mirror_path] ||= File.join(Monk.monk_mirrors, Time.now.to_i) if mirror
    end
    
    def update_mirror
      if mirror?       
        if File.exist? mirror_path
          system "cd #{mirror_path} && git pull origin -q 2>/dev/null"
        else
          system <<-EOS
            mkdir -p #{Monk.monk_mirrors}
            git clone -q #{url} #{mirror_path}
          EOS
        end
      end
    end
    
    def system(cmd)
      super
    end
    
    def create(directory) 
      update_mirror
      if Dir["#{directory}/*"].empty?
        self.target = directory
        return false unless system clone_command
        clean_up unless keep_remote?
        true
      end
    end
    
    def advanced_clone?
      branch? or keep_remote?
    end
    
    def clone_command
      advanced_clone? ? advanced_clone_command : fast_clone_command
    end
    
    def mirror_url
      mirror? ? @mirror_url : url
    end
    
    def fast_clone_command
      "git clone -q --depth 1 #{mirror_url} #{target}" 
    end
    
    def advanced_clone_command
      <<-EOS
        mkdir -p #{target} && cd target &&
        git init -q && git remote add -t #{branch} -f #{remote_name} #{mirror_url} &&
        git checkout -t #{remote}/#{branch}
      EOS
    end
    
    def clean_up
      Dir.chdir(target) { system "rm -Rf #{target}" }
    end
    
    def config
      options.keys == ["url"] ? options["url"] : Hash.new.replace(options)
    end
    
    def to_yaml(opts = {})
      config.to_yaml(opts)
    end
    
    def description
      options.map do |key, value|
        "#{key}: #{value}"
      end.join ", "
    end 
    
    def method_missing(name, *args, &block)
      return options[name] || DEFAULTS[name] if Monk.git_options.include? name.to_s
      result = options.send(name, *args, &block)
      if result.equal? options then self
      elsif result.is_a? Hash then Skeleton.new result
      else result
      end 
    end
    
  end
end