# typed: strict
# frozen_string_literal: true

class String
  extend T::Sig

  sig { returns(String) }
  def underscore
    return self unless /[A-Z-]|::/.match?(self)

    word = to_s.gsub("::", "/")
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end
end
