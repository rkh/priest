require 'thor/core_ext/hash_with_indifferent_access'
require 'monk'

class Monk < Thor
  class Skeleton
    
    include Thor::CoreExt    
    attr_accessor :options, :target
    
    DEFAULTS = { "remote_name" => "skeleton", "branch" => "master" }
    
    def initialize(url = nil, opts = {})     
      opts, url = opts.merge(url), nil if url.respond_to? :merge    
      self.options = HashWithIndifferentAccess.new opts
      options[:url] ||= url
      raise ArgumentError, "no url given" unless options.url?      
    end
    
    def mirror_path
      return unless mirror?
      options[:mirror_path] ||= begin        
        require 'digest/md5'
        File.join(Monk.monk_mirrors, Digest::MD5.hexdigest(options[:url]))
      end
    end
    
    def update_mirror
      return unless mirror?      
      if File.exist? mirror_path
        system "cd #{mirror_path} && git pull origin -q >/dev/null"
      else
        system <<-EOS
          mkdir -p #{Monk.monk_mirrors}
          git clone -q #{url} #{mirror_path}
        EOS
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
      mirror? ? mirror_path : url
    end
    
    def fast_clone_command
      "git clone -q --depth 1 #{mirror_url} #{target}" 
    end
    
    def advanced_clone_command
      <<-EOS
        mkdir -p #{target} && cd #{target} &&
        git init -q && git remote add -t #{branch} -f #{remote_name} #{mirror_url} &&
        git checkout -t #{remote_name}/#{branch} -q
      EOS
    end
    
    def clean_up
      Dir.chdir(target) { system "rm -Rf .git" }
    end
    
    def config
      options.keys == ["url"] ? options["url"] : Hash.new.replace(options)
    end
    
    def to_yaml(opts = {})
      config.to_yaml(opts)
    end
    
    def description
      parameters = options.map do |key, value|
        case key
        when "url", "mirror_path" then nil
        when "mirror", "keep_remote"
          "#{"no-" unless value}#{key.gsub("_", "-")}"
        else
          "#{key}: #{value.inspect}"
        end
      end.compact.join ", "
      parameters = "(#{parameters})" unless parameters.empty?
      "#{url} #{parameters}"
    end 
    
    def method_missing(name, *args, &block)
      name = name.to_s
      return options[name] || DEFAULTS[name] if Monk.git_options.include? name
      result = options.send(name, *args, &block)
      if result.equal? options then self
      elsif result.is_a? Hash then Skeleton.new result
      else result
      end 
    end
    
  end
end