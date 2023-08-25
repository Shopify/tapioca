## ActiveRecordStore

`Tapioca::Dsl::Compilers::ActiveRecordStore` decorates RBI files for all
classes that use [`ActiveRecord::Store`](https://api.rubyonrails.org/classes/ActiveRecord/Store.html).

For example, with the following class:

~~~rb
class User < ActiveRecord::Base
  store :settings, accessors: :theme
  store_accessor :settings, :power_source, prefix: :prefs
end
~~~

this compiler will produce an RBI file with the following content:
~~~rbi
# typed: true

class User
  include GeneratedStoredAttributesMethods

  module GeneratedStoredAttributesMethods
    sig { returns(T.untyped) }
    def prefs_power_source; end

    sig { params(value: T.untyped).returns(T.untyped) }
    def prefs_power_source=(value); end

    sig { returns(T.untyped) }
    def prefs_power_source_before_last_save; end

    sig { returns(T.untyped) }
    def prefs_power_source_change; end

    sig { returns(T::Boolean) }
    def prefs_power_source_changed?; end

    sig { returns(T.untyped) }
    def prefs_power_source_was; end

    sig { returns(T.untyped) }
    def saved_change_to_prefs_power_source; end

    sig { returns(T::Boolean) }
    def saved_change_to_prefs_power_source?; end

    sig { returns(T.untyped) }
    def saved_change_to_theme; end

    sig { returns(T::Boolean) }
    def saved_change_to_theme?; end

    sig { returns(T.untyped) }
    def theme; end

    sig { params(value: T.untyped).returns(T.untyped) }
    def theme=(value); end

    sig { returns(T.untyped) }
    def theme_before_last_save; end

    sig { returns(T.untyped) }
    def theme_change; end

    sig { returns(T::Boolean) }
    def theme_changed?; end

    sig { returns(T.untyped) }
    def theme_was; end
  end
end
~~~
