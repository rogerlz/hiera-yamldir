class Hiera
  module Backend
    class Yamldir_backend
      def initialize(cache=nil)
        require 'yaml'
        Hiera.debug("Hiera YAMLDir backend starting")

        @cache = cache || Filecache.new
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up #{key} in YAMLDir backend")

        datadir = Backend.datadir(:yamldir, scope)
        Backend.datasources(scope, order_override) do |source|
          if File.directory?(File.join(datadir, "#{source}"))
            Dir["#{datadir}/#{source}/**/*.yaml"].each do |yamlfile|
              data = @cache.read_file(yamlfile, Hash) do |data|
                Hiera.debug("Opening #{yamlfile}")
                YAML.load(data) || {}
              end

              next if data.empty?
              next unless data.include?(key)
              if data[key].respond_to?(:each)
                if answer.nil?
                  Hiera.debug("Found #{key} for the first time in #{source}")
                  answer = data[key]
                else
                  Hiera.debug("Found one more #{key} in #{source}. Merging..")
                  answer.merge!(data[key])
                end
              end

            end
          end
        end
        return answer
      end

      private

      def file_exists?(path)
        File.exist? path
      end
    end
  end
end
