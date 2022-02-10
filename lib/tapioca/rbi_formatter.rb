# typed: strict
# frozen_string_literal: true

module Tapioca
  class RBIFormatter < RBI::Formatter; end

  DEFAULT_RBI_FORMATTER = T.let(RBIFormatter.new(
    add_sig_templates: false,
    group_nodes: true,
    max_line_length: nil,
    nest_singleton_methods: true,
    nest_non_public_methods: true,
    sort_nodes: true
  ), RBIFormatter)
end
