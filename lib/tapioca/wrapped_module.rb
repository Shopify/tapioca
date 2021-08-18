# typed: true
# frozen_string_literal: true

module Tapioca
  class WrappedModule

    # This class represents a single candidate for a module/class definition.
    # It provides access to the source, documentation, line and file
    # for a monkeypatch (reopening) of a class/module.
    class Candidate

      # @return [String] The file where the module definition is located.
      attr_reader :file
      # alias source_file file

      # # @return [Fixnum] The line where the module definition is located.
      # attr_reader :line
      # alias source_line line

      # Methods to delegate to associated `Pry::WrappedModule
      # instance`.
      private_delegates = [:lines_for_file, :method_candidates, :yard_docs?, :name]
      public_delegates = [:wrapped, :module?, :class?, :nonblank_name,
                          :number_of_candidates]

      def_delegators :@wrapper, *public_delegates
      def_private_delegators :@wrapper, *private_delegates

      # @raise [Pry::CommandError] If `rank` is out of bounds.
      # @param [Pry::WrappedModule] wrapper The associated
      #   `Pry::WrappedModule` instance that owns the candidates.
      # @param [Fixnum] rank The rank of the candidate to
      #   retrieve. Passing 0 returns 'primary candidate' (the candidate with largest
      #   number of methods), passing 1 retrieves candidate with
      #   second largest number of methods, and so on, up to
      #   `Pry::WrappedModule#number_of_candidates() - 1`
      def initialize(wrapper, rank)
        @wrapper = wrapper

        if number_of_candidates <= 0
          raise ArgumentError, "Cannot find a definition for #{name} module!"
        end

        if rank > (number_of_candidates - 1)
          raise ArgumentError,
                "No such module candidate. Allowed candidates range is " \
                "from 0 to #{number_of_candidates - 1}"
        end

        @source = @source_location = nil
        @rank = rank
        @file, @line = source_location
      end

      # # @raise [Pry::CommandError] If source code cannot be found.
      # # @return [String] The source for the candidate, i.e the
      # #   complete module/class definition.
      # def source
      #   return nil if file.nil?
      #   return @source if @source

      #   @source ||= strip_leading_whitespace(
      #     Pry::Code.from_file(file).expression_at(line, number_of_lines_in_first_chunk)
      #   )
      # end

      # # @raise [Pry::CommandError] If documentation cannot be found.
      # # @return [String] The documentation for the candidate.
      # def doc
      #   return nil if file.nil?

      #   @doc ||= get_comment_content(Pry::Code.from_file(file).comment_describing(line))
      # end

      # # @return [Array, nil] A `[String, Fixnum]` pair representing the
      # #   source location (file and line) for the candidate or `nil`
      # #   if no source location found.
      # def source_location
      #   return @source_location if @source_location

      #   file, line = first_method_source_location
      #   return nil unless file.is_a?(String)

      #   @source_location = [file, first_line_of_module_definition(file, line)]
      # rescue Pry::RescuableException
      #   nil
      # end

      private

      # # Locate the first line of the module definition.
      # # @param [String] file The file that contains the module
      # #   definition (somewhere).
      # # @param [Fixnum] line The module definition should appear
      # #   before this line (if it exists).
      # # @return [Fixnum] The line where the module is defined. This
      # #   line number is one-indexed.
      # def first_line_of_module_definition(file, line)
      #   searchable_lines = lines_for_file(file)[0..(line - 2)]
      #   searchable_lines.rindex { |v| class_regexes.any? { |r| r =~ v } } + 1
      # end

      # def class_regexes
      #   mod_type_string = wrapped.class.to_s.downcase
      #   [/(^|=)\s*#{mod_type_string}\s+(?:(?:\w*)::)*?#{wrapped.name.split(/::/).last}/,
      #    /^\s*(::)?#{wrapped.name.split(/::/).last}\s*?=\s*?#{wrapped.class}/,
      #    /^\s*(::)?#{wrapped.name.split(/::/).last}\.(class|instance)_eval/]
      # end

      # # This method is used by `Candidate#source_location` as a
      # # starting point for the search for the candidate's definition.
      # # @return [Array] The source location of the base method used to
      # #   calculate the source location of the candidate.
      # def first_method_source_location
      #   @first_method_source_location ||= method_candidates[@rank].first.source_location
      # end

      # # @return [Array] The source location of the last method in this
      # #   candidate's module definition.
      # def last_method_source_location
      #   @last_method_source_location ||= method_candidates[@rank].last.source_location
      # end

      # # Return the number of lines between the start of the class definition and
      # # the start of the last method. We use this value so we can quickly grab
      # # these lines from the file (without having to check each intervening line
      # # for validity, which is expensive) speeding up source extraction.
      # #
      # # @return [Integer] number of lines.
      # def number_of_lines_in_first_chunk
      #   end_method_line = last_method_source_location.last

      #   end_method_line - line
      # end
    end


    attr_reader :wrapped

    # @raise [ArgumentError] if the argument is not a `Module`
    # @param [Module] mod
    def initialize(mod)
      unless mod.is_a?(Module)
        raise ArgumentError, "Tried to initialize a WrappedModule with a " \
                             "non-module #{mod.inspect}"
      end

      @wrapped = mod
      @memoized_candidates = []
      @host_file_lines = nil
      @source = nil
      @source_location = nil
      @doc = nil
      @all_source_locations_by_popularity = nil
    end

  #   # Returns an array of the names of the constants accessible in the wrapped
  #   # module. This avoids the problem of accidentally calling the singleton
  #   # method `Module.constants`.
  #   # @param [Boolean] inherit Include the names of constants from included
  #   #   modules?
  #   def constants(inherit = true)
  #     Module.instance_method(:constants).bind(@wrapped).call(inherit)
  #   end

  #   # The prefix that would appear before methods defined on this class.
  #   #
  #   # i.e. the "String." or "String#" in String.new and String#initialize.
  #   #
  #   # @return String
  #   def method_prefix
  #     if singleton_class?
  #       if Module === singleton_instance # rubocop:disable Style/CaseEquality
  #         "#{WrappedModule.new(singleton_instance).nonblank_name}."
  #       else
  #         "self."
  #       end
  #     else
  #       "#{nonblank_name}#"
  #     end
  #   end

  #   # The name of the Module if it has one, otherwise #<Class:0xf00>.
  #   #
  #   # @return [String]
  #   def nonblank_name
  #     if name.to_s == ""
  #       wrapped.inspect
  #     else
  #       name
  #     end
  #   end

  #   # Is this a singleton class?
  #   # @return [Boolean]
  #   def singleton_class?
  #     if Pry::Method.safe_send(wrapped, :respond_to?, :singleton_class?)
  #       Pry::Method.safe_send(wrapped, :singleton_class?)
  #     else
  #       wrapped != Pry::Method.safe_send(wrapped, :ancestors).first
  #     end
  #   end

  #   # Is this strictly a module? (does not match classes)
  #   # @return [Boolean]
  #   def module?
  #     wrapped.instance_of?(Module)
  #   end

  #   # Is this strictly a class?
  #   # @return [Boolean]
  #   def class?
  #     wrapped.instance_of?(Class)
  #   end

  #   # Get the instance associated with this singleton class.
  #   #
  #   # @raise ArgumentError: tried to get instance of non singleton class
  #   #
  #   # @return [Object]
  #   def singleton_instance
  #     unless singleton_class?
  #       raise ArgumentError, "tried to get instance of non singleton class"
  #     end

  #     if Helpers::Platform.jruby?
  #       wrapped.to_java.attached
  #     else
  #       @singleton_instance ||= ObjectSpace.each_object(wrapped).detect do |x|
  #         (class << x; self; end) == wrapped
  #       end
  #     end
  #   end

  #   # Forward method invocations to the wrapped module
  #   def method_missing(method_name, *args, &block)
  #     if wrapped.respond_to?(method_name)
  #       wrapped.send(method_name, *args, &block)
  #     else
  #       super
  #     end
  #   end

  #   def respond_to_missing?(method_name, include_private = false)
  #     wrapped.respond_to?(method_name, include_private) || super
  #   end

  #   # Retrieve the source location of a module. Return value is in same
  #   # format as Method#source_location. If the source location
  #   # cannot be found this method returns `nil`.
  #   #
  #   # @return [Array<String, Fixnum>, nil] The source location of the
  #   #   module (or class), or `nil` if no source location found.
  #   def source_location
  #     @source_location ||= primary_candidate.source_location
  #   rescue Pry::RescuableException
  #     nil
  #   end

  #   # @return [String, nil] The associated file for the module (i.e
  #   #   the primary candidate: highest ranked monkeypatch).
  #   def file
  #     Array(source_location).first
  #   end
  #   alias source_file file

  #   # @return [Fixnum, nil] The associated line for the module (i.e
  #   #   the primary candidate: highest ranked monkeypatch).
  #   def line
  #     Array(source_location).last
  #   end
  #   alias source_line line

  #   # Returns documentation for the module.
  #   # This documentation is for the primary candidate, if
  #   # you would like documentation for other candidates use
  #   # `WrappedModule#candidate` to select the candidate you're
  #   # interested in.
  #   # @raise [Pry::CommandError] If documentation cannot be found.
  #   # @return [String] The documentation for the module.
  #   def doc
  #     @doc ||= primary_candidate.doc
  #   end

  #   # Returns the source for the module.
  #   # This source is for the primary candidate, if
  #   # you would like source for other candidates use
  #   # `WrappedModule#candidate` to select the candidate you're
  #   # interested in.
  #   # @raise [Pry::CommandError] If source cannot be found.
  #   # @return [String] The source for the module.
  #   def source
  #     @source ||= primary_candidate.source
  #   end

  #   # @return [String] Return the associated file for the
  #   #   module from YARD, if one exists.
  #   def yard_file
  #     YARD::Registry.at(name).file if yard_docs?
  #   end

  #   # @return [Fixnum] Return the associated line for the
  #   #   module from YARD, if one exists.
  #   def yard_line
  #     YARD::Registry.at(name).line if yard_docs?
  #   end

  #   # @return [String] Return the YARD docs for this module.
  #   def yard_doc
  #     YARD::Registry.at(name).docstring.to_s if yard_docs?
  #   end

    # Return a candidate for this module of specified rank. A `rank`
    # of 0 is equivalent to the 'primary candidate', which is the
    # module definition with the highest number of methods. A `rank`
    # of 1 is the module definition with the second highest number of
    # methods, and so on. Module candidates are necessary as modules
    # can be reopened multiple times and in multiple places in Ruby,
    # the candidate API gives you access to the module definition
    # representing each of those reopenings.
    # @raise [Pry::CommandError] If the `rank` is out of range. That
    #   is greater than `number_of_candidates - 1`.
    # @param [Fixnum] rank
    # @return [Pry::WrappedModule::Candidate]
    def candidate(rank)
      @memoized_candidates[rank] ||= WrappedModule::Candidate.new(self, rank)
    end

    # @return [Fixnum] The number of candidate definitions for the
    #   current module.
    def number_of_candidates
      method_candidates.count
    end

    # @note On JRuby 1.9 and higher, in certain conditions, this method chucks
    #   away its ability to be quick (when there are lots of monkey patches,
    #   like in Rails). However, it should be efficient enough on other rubies.
    # @see https://github.com/jruby/jruby/issues/525
    # @return [Enumerator, Array] on JRuby 1.9 and higher returns Array, on
    #  other rubies returns Enumerator
    def candidates
      Enumerator.new do |y|
        (0...number_of_candidates).each do |num|
          y.yield candidate(num)
        end
      end
    end

  #   # @return [Boolean] Whether YARD docs are available for this module.
  #   def yard_docs?
  #     !!(defined?(YARD) && YARD::Registry.at(name))
  #   end

  #   # @param [Fixnum] times How far to travel up the ancestor chain.
  #   # @return [Pry::WrappedModule, nil] The wrapped module that is the
  #   #   superclass.
  #   #   When `self` is a `Module` then return the
  #   #   nth ancestor, otherwise (in the case of classes) return the
  #   #   nth ancestor that is a class.
  #   def super(times = 1)
  #     return self if times.zero?

  #     sup =
  #       if wrapped.is_a?(Class)
  #         ancestors.select { |v| v.is_a?(Class) }[times]
  #       else
  #         ancestors[times]
  #       end

  #     Pry::WrappedModule(sup) if sup
  #   end

  #   private

  #   # @return [Pry::WrappedModule::Candidate] The candidate with the
  #   #   highest rank, that is the 'monkey patch' of this module with the
  #   #   highest number of methods, which contains a source code line that
  #   #   defines the module. It is considered the 'canonical' definition
  #   #   for the module. In the absense of a suitable candidate, the
  #   #   candidate of rank 0 will be returned, or a CommandError raised if
  #   #   there are no candidates at all.
  #   def primary_candidate
  #     @primary_candidate ||= candidates.find(&:file) || candidate(0)
  #   end

  #   # @return [Array<Array<Pry::Method>>] The array of `Pry::Method` objects,
  #   #   there are two associated with each candidate. The first is the 'base
  #   #   method' for a candidate and it serves as the start point for
  #   #   the search in  uncovering the module definition. The second is
  #   #   the last method defined for that candidate and it is used to
  #   #   speed up source code extraction.
    def method_candidates
      @method_candidates ||= all_source_locations_by_popularity.map do |group|
        methods_sorted_by_source_line = group.last.sort_by(&:source_line)
        [methods_sorted_by_source_line.first, methods_sorted_by_source_line.last]
      end
    end

    # A helper method.
    def all_source_locations_by_popularity
      return @all_source_locations_by_popularity if @all_source_locations_by_popularity

      ims = all_relevant_methods_for(wrapped).group_by do |v|
        Array(v.source_location).first
      end

      @all_source_locations_by_popularity = ims.sort_by do |path, methods|
        expanded = File.expand_path(path)
        load_order = $LOADED_FEATURES.index { |file| expanded.end_with?(file) }

        [-methods.size, load_order || (1.0 / 0.0)]
      end
    end

    # We only want methods that have a non-nil `source_location`. We also
    # skip some spooky internal methods.
    #
    # @return [Array<Pry::Method>]
    def all_relevant_methods_for(mod)
      methods = all_methods_for(mod).select(&:source_location)
        .reject { |x| method_defined_by_forwardable_module?(x) }

      return methods unless methods.empty?

      safe_send(mod, :constants).flat_map do |const_name|
        if (const = nested_module?(mod, const_name))
          all_relevant_methods_for(const)
        else
          []
        end
      end
    end

    # Return all methods (instance methods and class methods) for a
    # given module.
    # @return [Array<Pry::Method>]
    def all_methods_for(mod)
      Pry::Method.all_from_obj(mod, false) + Pry::Method.all_from_class(mod, false)
    end

  #   def nested_module?(parent, name)
  #     return if safe_send(parent, :autoload?, name)

  #     child = safe_send(parent, :const_get, name)
  #     return unless child.is_a?(Module)
  #     return unless safe_send(child, :name) == "#{safe_send(parent, :name)}::#{name}"

  #     child
  #   end

  #   # Detect methods that are defined with `def_delegator` from the Forwardable
  #   # module. We want to reject these methods as they screw up module
  #   # extraction since the `source_location` for such methods points at forwardable.rb
  #   # TODO: make this more robust as valid user-defined files called
  #   # forwardable.rb are also skipped.
  #   def method_defined_by_forwardable_module?(method)
  #     method.source_location.first =~ /forwardable\.rb/
  #   end

  #   # memoized lines for file
  #   def lines_for_file(file)
  #     @lines_for_file ||= {}

  #     @lines_for_file[file] ||=
  #       if file == Pry.eval_path
  #         Pry.line_buffer.drop(1)
  #       else
  #         File.readlines(file)
  #       end
  #   end
  end
end
