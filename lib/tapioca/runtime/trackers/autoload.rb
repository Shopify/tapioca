# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module Autoload
        extend Tracker
        extend T::Sig

        NOOP_METHOD = ->(*_args, **_kwargs, &_block) {}

        @constant_names_registered_for_autoload = T.let([], T::Array[String])

        class << self
          extend T::Sig

          sig { params(bundle: Gemfile).void }
          def eager_load_all!(bundle)
            start = Time.now
            with_disabled_exits do
              start_registering = Time.now
              register_autoloads_for_bundle(bundle)
              finish_registering = Time.now
              puts "Registered all autoloads in #{finish_registering - start_registering} seconds"
              return # TODO
              @constant_names_registered_for_autoload -= CONSTANTS_TO_SKIP
              start_loading = Time.now
              until @constant_names_registered_for_autoload.empty?
                begin
                  # Grab the next constant name
                  constant_name = T.must(@constant_names_registered_for_autoload.shift)
                  # Trigger autoload by constantizing the registered name

                  Reflection.constantize(constant_name)
                  puts "Successfully eager loaded #{constant_name}"
                rescue Exception => e # rubocop:disable Lint/RescueException
                  puts "Error while eager loading #{constant_name}: #{e.message}"
                end
              end
              finish_loading = Time.now
              puts "Finished loading constants in #{finish_loading - start_loading} seconds"
            end
            finish = Time.now
            puts "Eager loaded all constants in #{finish - start} seconds"
          end

          sig { params(constant_name: String).void }
          def register(constant_name)
            return unless enabled?

            @constant_names_registered_for_autoload << constant_name
          end

          private

          def register_autoloads_for_bundle(bundle)
            autoload_list = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] } }

            index = ::RubyIndexer::Index.new

            files = bundle.dependencies.flat_map(&:files)
            # puts files
            Benchmark.realtime do
              files.each do |file|
                index.index_single(file)
              rescue Errno::ENOENT
                # puts "File #{file} does not exist"
              end
            end
            return

            # paths_with_symbols = Static::SymbolLoader.gem_symbols_with_paths(gem)

            # paths_with_symbols.each do |path, symbols|
            #   symbols.each do |symbol|
            #     previous = ""

            #     symbol.split("::").each do |part|
            #       autoload_list[previous][part] << path
            #       previous = previous.empty? ? part : "#{previous}::#{part}"
            #     end
            #   end
            # end

            # Sort the list of autoloads by the number of components in the constant name and the length of the name.
            autoload_list.transform_values do |part_to_paths_map|
              part_to_paths_map.transform_values(&:uniq!)
            end.sort_by do |constant_name|
              [constant_name.count(":"), constant_name.size]
            end

            # File.write("autload-map.json", JSON.pretty_generate(autoload_list))

            autoload_list.each do |constant_name, part_to_paths_map|
              part_to_paths_map.each do |part, paths|
                # The following is a terrible heuristic to map a constant to the shortest (in number of components) path
                path = paths.sort_by { |p| p.to_s.split("/").size }.first
                constant = if constant_name.empty?
                  Object
                elsif Object.const_defined?(constant_name)
                  Object.const_get(constant_name)
                end

                next unless constant
                next unless Module === constant
                next if constant.autoload?(part.to_sym) # there is already an autoload for this constant

                # puts "== Registering autoload for #{constant}::#{part} from #{path}"
                constant.autoload(part.to_sym, path.to_s)
                # puts "== Registered the autoload for #{constant}::#{part} from #{path}"
              rescue Exception => ex # rubocop:disable Lint/RescueException
                puts "== Failed to register the autoload for #{constant}::#{part} from #{path}: #{ex}"
              end
            end
          end

          sig do
            type_parameters(:Result)
              .params(block: T.proc.returns(T.type_parameter(:Result)))
              .returns(T.type_parameter(:Result))
          end
          def with_disabled_exits(&block)
            original_abort = Kernel.instance_method(:abort)
            original_exit = Kernel.instance_method(:exit)

            begin
              Kernel.define_method(:abort, NOOP_METHOD)
              Kernel.define_method(:exit, NOOP_METHOD)

              block.call
            ensure
              Kernel.define_method(:exit, original_exit)
              Kernel.define_method(:abort, original_abort)
            end
          end
        end
      end
    end
  end
end

# We need to do the alias-method-chain dance since Bootsnap does the same,
# and prepended modules and alias-method-chain don't play well together.
#
# So, why does Bootsnap do alias-method-chain and not prepend? Glad you asked!
# That's because RubyGems does alias-method-chain for Kernel#require and such,
# so, if Bootsnap were to do prepend, it might end up breaking RubyGems.
class Module
  alias_method(:autoload_without_tapioca, :autoload)

  def autoload(const_name, path)
    Tapioca::Runtime::Trackers::Autoload.register("#{self}::#{const_name}")
    autoload_without_tapioca(const_name, path)
  end
end
