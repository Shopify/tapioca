# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class Mixins < Base
        extend T::Sig

        include Reflection

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          constant = event.constant
          singleton_class = singleton_class_of(constant)

          interesting_ancestors = interesting_ancestors_of(constant)
          interesting_singleton_class_ancestors = interesting_ancestors_of(singleton_class)

          prepends = interesting_ancestors.take_while { |c| !are_equal?(constant, c) }
          includes = interesting_ancestors.drop(prepends.size + 1)
          extends  = interesting_singleton_class_ancestors.reject do |mod|
            Module != class_of(mod) || are_equal?(mod, singleton_class)
          end

          node = event.node
          add_mixins(node, prepends.reverse, Trackers::Mixin::Type::Prepend)
          add_mixins(node, includes.reverse, Trackers::Mixin::Type::Include)
          add_mixins(node, extends.reverse, Trackers::Mixin::Type::Extend)
        end

        sig do
          params(
            tree: RBI::Tree,
            mods: T::Array[Module],
            mixin_type: Trackers::Mixin::Type
          ).void
        end
        def add_mixins(tree, mods, mixin_type)
          mods
            .select do |mod|
              name = @pipeline.name_of(mod)

              name && !filtered_mixin?(name)
            end
            .map do |mod|
              name = @pipeline.name_of(mod)
              @pipeline.push_symbol(name) if name

              qname = qualified_name_of(mod)
              case mixin_type
              # TODO: Sorbet currently does not handle prepend
              # properly for method resolution, so we generate an
              # include statement instead
              when Trackers::Mixin::Type::Include, Trackers::Mixin::Type::Prepend
                tree << RBI::Include.new(T.must(qname))
              when Trackers::Mixin::Type::Extend
                tree << RBI::Extend.new(T.must(qname))
              end
            end
        end

        sig { params(mixin_name: String).returns(T::Boolean) }
        def filtered_mixin?(mixin_name)
          # filter T:: namespace mixins that aren't T::Props
          # T::Props and subconstants have semantic value
          mixin_name.start_with?("T::") && !mixin_name.start_with?("T::Props")
        end

        sig { params(constant: Module).returns(T::Array[Module]) }
        def interesting_ancestors_of(constant)
          inherited_ancestors_ids = Set.new(
            inherited_ancestors_of(constant).map { |mod| object_id_of(mod) }
          )
          # TODO: There is actually a bug here where this will drop modules that
          # may be included twice. For example:
          #
          # ```ruby
          # class Foo
          #   prepend Kernel
          # end
          # ````
          # would give:
          # ```ruby
          # Foo.ancestors #=> [Kernel, Foo, Object, Kernel, BasicObject]
          # ````
          # but since we drop `Kernel` whenever we match it, we would miss
          # the `prepend Kernel` in the output.
          #
          # Instead, we should only drop the tail matches of the ancestors and
          # inherited ancestors, past the location of the constant itself.
          constant.ancestors.reject do |mod|
            inherited_ancestors_ids.include?(object_id_of(mod))
          end
        end
      end
    end
  end
end
