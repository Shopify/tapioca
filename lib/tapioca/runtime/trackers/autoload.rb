# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module Autoload
        extend Tracker

        @constant_names_registered_for_autoload = [] #: Array[String]

        class << self
          #: -> void
          def eager_load_all!
            Runtime.with_disabled_exits do
              until @constant_names_registered_for_autoload.empty?
                # Grab the next constant name
                constant_name = T.must(@constant_names_registered_for_autoload.shift)
                # Trigger autoload by constantizing the registered name
                Reflection.constantize(constant_name, inherit: true)
              end
            end
          end

          #: (String constant_name) -> void
          def register(constant_name)
            return unless enabled?

            @constant_names_registered_for_autoload << constant_name
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
