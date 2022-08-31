# typed: strict
# frozen_string_literal: true

require "tapioca/internal"
require "active_support"
require "rbs"

class RbsConverter
  extend T::Sig
  include Tapioca::RBIHelper

  module NameHelper
    extend T::Sig

    private

    sig { params(name: RBS::TypeName).returns(String) }
    def interface_name(name)
      "#{name.namespace}Converted_Interface#{name.name}"
    end

    sig { params(name: RBS::TypeName).returns(String) }
    def type_alias_name(name)
      "#{name.namespace}Converted_TypeAlias_#{name.name}"
    end
  end

  include NameHelper

  class TypeConverter
    extend T::Sig
    include NameHelper

    sig { params(type_params: T::Array[RBS::AST::TypeParam]).void }
    def initialize(type_params = [])
      @type_params = type_params
      @type_param_names = T.let(type_params.map(&:to_s), T::Array[String])
    end

    sig { returns(T::Array[RBS::AST::TypeParam]) }
    attr_reader :type_params

    sig { params(type: T.untyped).returns(T::Types::Base) }
    def map_type(type)
      case type
      when RBS::Types::Alias
        case type.name.name.to_s
        when "boolish"
          T.untyped
        else
          name = type_alias_name(type.name)
          string_holder(name)
        end
      when RBS::Types::Bases::Any
        # "T.untyped"
        T.untyped
      when RBS::Types::Bases::Bool
        # "T::Boolean"
        T::Boolean
      when RBS::Types::Bases::Bottom
        T.untyped
      when RBS::Types::Bases::Instance
        # "T.attached_class"
        T::Types::AttachedClassType::Private.const_get(:INSTANCE)
      when RBS::Types::Bases::Nil
        # "NilClass"
        T::Utils.coerce(NilClass)
      when RBS::Types::Bases::Self
        # "T.self_type"
        T.self_type
      when RBS::Types::Bases::Top
        T::Utils.coerce(BasicObject)
      when RBS::Types::Bases::Void
        # "void"
        T::Private::Types::Void.new
      when ::RBS::Types::Bases::Class
        # unhandled
      when RBS::Types::ClassInstance
        prefix = ""
        prefix = "T::" if ["Hash", "Array", "Set", "Enumerable", "Enumerable::Lazy", "Enumerator", "Range"].include?(type.name.to_s) && !type.args.empty?
        name = prefix + type.name.to_s

        type_variables = type.args.map { |arg| map_type(arg).to_s }.join(", ")
        name += "[#{type_variables}]" unless type_variables.empty?

        string_holder(name)
      when RBS::Types::Interface
        name = case type.name.name.to_s
        when "_Each"
          "T::Enumerable"
        else
          interface_name(type.name)
        end
        type_variables = type.args.map { |arg| map_type(arg).to_s }.join(", ")
        name += "[#{type_variables}]" unless type_variables.empty?

        string_holder(name)
      when RBS::Types::Intersection
        T.unsafe(T).all(*type.types.map { |type| map_type(type) })
      when RBS::Types::Literal
        T.untyped
      when RBS::Types::Optional
        type = map_type(type.type)
        if T::Types::Untyped === type
          type
        else
          T.nilable(T.unsafe(type))
        end
      when RBS::Types::Proc
        converter = ParameterConverter.new(self, type.type, type.block)
        params = converter.convert.to_h { |p| [p[:name], p[:type]] }
        T::Types::Proc.new(params, map_type(type.type.return_type))
      when RBS::Types::Record
        T::Utils.coerce(type.fields.to_h { |key, type| [key, map_type(type)] })
      when RBS::Types::Tuple
        T::Utils.coerce(type.types.map { |type| map_type(type) })
      when RBS::Types::Union
        T.unsafe(T).any(*type.types.map { |type| map_type(type) })
      when RBS::Types::Variable
        if @type_param_names.include?(type.name.to_s)
          T::Types::TypeParameter.new(type.name.to_sym)
        else
          string_holder(type.name.to_s)
        end
      when RBS::Types::ClassSingleton
        # Don't know how to handle this...
        T.untyped
      when RBS::Types::Block
        converter = ParameterConverter.new(self, type.type, nil)
        params = converter.convert.to_h { |p| [p[:name], p[:type]] }
        block = T::Types::Proc.new(params, map_type(type.type.return_type))
        block = T.nilable(T.unsafe(block)) unless type.required
        block
      else
        raise "Unknown RBS type: #{type.class}>"
      end
    end

    sig { params(visibility: Symbol).returns(RBI::Visibility) }
    def visibility(visibility)
      case visibility
      when :public
        RBI::Public.new
      when :private
        RBI::Private.new
      else
        raise "Unknown visibility: `#{visibility}`"
      end
    end

    private

    sig { params(type_name: String).returns(T::Private::Types::StringHolder) }
    def string_holder(type_name)
      T.unsafe(T::Private::Types::StringHolder).new(type_name)
    end
  end

  class ParameterConverter
    extend T::Sig
    include Tapioca::RBIHelper

    sig { params(type_converter: TypeConverter, type: RBS::Types::Function, block: T.nilable(RBS::Types::Block)).void }
    def initialize(type_converter, type, block)
      @type = type
      @type_converter = type_converter
      @block = block
    end

    sig { returns(T::Array[{ kind: Symbol, name: String, type: T::Types::Base}]) }
    def convert
      parameters = [
        *@type.required_positionals.map { |param| [:req, nil, param] },
        *@type.optional_positionals.map { |param| [:opt, nil, param] },
        *Array(@type.rest_positionals).map { |param| [:rest, nil, param] },
        *@type.trailing_positionals.map { |param| [:opt, nil, param] },
        *@type.required_keywords.map { |name, param| [:keyreq, name, param] },
        *@type.optional_keywords.map { |name, param| [:key, name, param] },
        *Array(@type.rest_keywords).map { |param| [:keyrest, nil, param] },
      ]

      result = parameters.map.with_index do |(kind, name, param), index|
        name = param.name unless name
        name = (name || "_arg#{index}").to_s
        param_type = @type_converter.map_type(param.type)

        { kind: kind, name: name, type: param_type }
      end

      if @block
        result << { kind: :block, name: "blk", type: @type_converter.map_type(@block) }
      end

      result
    end
  end

  class MethodConverter
    extend T::Sig
    include Tapioca::RBIHelper

    sig { params(method_type: RBS::MethodType, name: String, is_singleton: T::Boolean, visibility: Symbol).void }
    def initialize(method_type, name = "", is_singleton = false, visibility = :public)
      @name = name
      @is_singleton = is_singleton
      @visibility = visibility
      @type_converter = T.let(TypeConverter.new(method_type.type_params), RbsConverter::TypeConverter)
      @param_converter = T.let(ParameterConverter.new(@type_converter, method_type.type, method_type.block), RbsConverter::ParameterConverter)
      @return_type = T.let(method_type.type.return_type, T.untyped)
    end

    sig { returns(RBI::Method) }
    def to_rbi_method
      RBI::Method.new(@name, is_singleton: @is_singleton, visibility: visibility) do |method|
        each_param do |param|
          method << param
        end
        method.sigs << signature
      end
    end

    sig { params(block: T.proc.params(param: RBI::Param).void).void }
    def each_param(&block)
      @param_converter.convert.each do |param|
        kind, name = param.values_at(:kind, :name)

        rbi_param = case kind
        when :req
          RBI::Param.new(name)
        when :opt
          RBI::OptParam.new(name, "T.unsafe(nil)")
        when :rest
          RBI::RestParam.new(name)
        when :keyreq
          RBI::KwParam.new(name)
        when :key
          RBI::KwOptParam.new(name, "T.unsafe(nil)")
        when :keyrest
          RBI::KwRestParam.new(name)
        when :block
          RBI::BlockParam.new(name)
        end

        block.call(T.must(rbi_param))
      end
    end

    sig { returns(RBI::Sig) }
    def signature
      sig = RBI::Sig.new

      # Type parameters
      @type_converter.type_params.each do |type_param|
        sig.type_params << type_param.to_s
      end

      # Parameters
      @param_converter.convert.each do |param|
        name, param_type = param.values_at(:name, :type)
        sig << RBI::SigParam.new(name, param_type.to_s)
      end

      # Return type
      sig.return_type = sanitize_signature_types(@type_converter.map_type(@return_type).to_s)

      sig
    end

    private

    sig { returns(RBI::Visibility) }
    def visibility
      @type_converter.visibility(@visibility)
    end
  end

  sig { params(scope: RBI::NodeWithComments, comment: T.nilable(RBS::AST::Comment)).void }
  def add_comments(scope, comment)
    return unless comment

    comment.string.lines.each do |line|
      scope.comments << RBI::Comment.new(line)
    end
  end

  sig { params(scope: RBI::Scope, decl: T.any(::RBS::AST::Declarations::Class, ::RBS::AST::Declarations::Interface, ::RBS::AST::Declarations::Module)).void }
  def process_scope(scope, decl)
    add_comments(scope, decl.comment)

    scope.create_extend("T::Generic") if decl.type_params.any?

    decl.type_params.each do |type_param|
      scope.create_constant(type_param.name.to_s, value: "type_member")
    end

    current_visibility = T.let(:public, Symbol)

    decl.members.each do |member|
      case member
      when RBS::AST::Members::Alias
        scope << RBI::Send.new("alias") do |node|
          node << RBI::Arg.new("#{member.new_name} #{member.old_name}")
          # node.comments << loc_comment(member.location)
        end
      when RBS::AST::Members::ClassInstanceVariable
      when RBS::AST::Members::ClassVariable
      when RBS::AST::Members::InstanceVariable
      when RBS::AST::Members::Private
        current_visibility = :private
      when RBS::AST::Members::Public
        current_visibility = :public
      when RBS::AST::Members::MethodDefinition
        converter = MethodConverter.new(
          T.must(member.types.first),
          member.name.to_s,
          member.singleton?,
          member.visibility || current_visibility,
        )
        method = converter.to_rbi_method
        add_comments(method, member.comment)
        # method.comments << loc_comment(member.location)
        scope << method
      when RBS::AST::Members::AttrReader
        return_type = type_converter.map_type(member.type).to_s
        visibility = type_converter.visibility(member.visibility || current_visibility)

        scope.create_method(member.name.to_s, return_type: return_type, visibility: visibility) do |method|
          # method.comments << loc_comment(member.location)
        end
      when RBS::AST::Members::AttrWriter
        parameters = [create_param(member.name.to_s, type: type_converter.map_type(member.type).to_s)]
        visibility = type_converter.visibility(member.visibility || current_visibility)

        scope.create_method(member.name.to_s, parameters: parameters, return_type: "void", visibility: visibility) do |method|
          # method.comments << loc_comment(member.location)
        end
      when RBS::AST::Members::AttrAccessor
        parameters = [create_param(member.name.to_s, type: type_converter.map_type(member.type).to_s)]
        return_type = type_converter.map_type(member.type).to_s
        visibility = type_converter.visibility(member.visibility || current_visibility)

        scope.create_method(member.name.to_s, return_type: return_type, visibility: visibility) do |method|
          # method.comments << loc_comment(member.location)
        end

        scope.create_method(member.name.to_s, parameters: parameters, return_type: "void", visibility: visibility) do |method|
          # method.comments << loc_comment(member.location)
        end
      when RBS::AST::Members::Include, RBS::AST::Members::Prepend
        name = if member.name.kind == :interface
          interface_name(member.name)
        else
          member.name.to_s
        end
        scope.create_include(name)
      when RBS::AST::Members::Extend
        name = if member.name.kind == :interface
          interface_name(member.name)
        else
          member.name.to_s
        end
        scope.create_extend(name)
      else
        # This is a nested declaration, hoist it to top level.
        process_declaration(T.unsafe(member))
      end
    end
  end

  sig { returns(RbsConverter::TypeConverter) }
  def type_converter
    @type_converter ||= T.let(TypeConverter.new, T.nilable(RbsConverter::TypeConverter))
  end

  sig { params(decl: T.untyped).void }
  def process_declaration(decl)
    case decl
    when RBS::AST::Declarations::Global
    when RBS::AST::Declarations::Class
      @root.create_class(decl.name.to_s, superclass_name: decl.super_class&.name&.to_s) do |scope|
        process_scope(scope, decl)
      end
    when RBS::AST::Declarations::Module
      return if decl.name.to_s == "::Enumerable"
      @root.create_module(decl.name.to_s) do |scope|
        process_scope(scope, decl)
        # scope.comments << loc_comment(decl.location)
      end
    when RBS::AST::Declarations::Constant
      node = RBI::Const.new(decl.name.to_s, "T.let(T.unsafe(nil), #{type_converter.map_type(decl.type)})")
      # node.comments << loc_comment(decl.location)
      @root << node
    when RBS::AST::Declarations::Alias
      name = type_alias_name(decl.name)
      node = RBI::Const.new(name, "T.type_alias { #{type_converter.map_type(decl.type)} }")
      # node.comments << loc_comment(decl.location)
      @root << node
    when RBS::AST::Declarations::Interface
      name = interface_name(decl.name)
      @root.create_module(name) do |scope|
        process_scope(scope, decl)
        # scope.comments << loc_comment(decl.location)
      end
    end
  end

  sig { params(gem_name: String).void }
  def initialize(gem_name)
    repo = RBS::Repository.new(no_stdlib: true)
    loader = RBS::EnvironmentLoader.new(repository: repo, core_root: nil)
    T.unsafe(loader).add(library: gem_name)
    @env = T.let(RBS::Environment.from_loader(loader).resolve_type_names, RBS::Environment)
    @root = T.let(RBI::Tree.new, RBI::Tree)
  end

  sig { params(loc: T.untyped).returns(RBI::Comment) }
  def loc_comment(loc)
    RBI::Comment.new("file://#{loc.buffer.name}##{loc.start_line}")
  end

  sig { returns(RBI::Tree) }
  def convert
    @env.declarations.each do |decl|
      process_declaration(decl)
    end
    @root
  end
end
