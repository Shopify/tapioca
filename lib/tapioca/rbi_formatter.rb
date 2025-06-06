# typed: strict
# frozen_string_literal: true

module Tapioca
  class RBIFormatter < RBI::Formatter
    extend T::Sig

    #: (RBI::File file, String command, ?reason: String?) -> void
    def write_header!(file, command, reason: nil)
      file.comments << RBI::Comment.new("DO NOT EDIT MANUALLY")
      file.comments << RBI::Comment.new("This is an autogenerated file for #{reason}.") unless reason.nil?
      file.comments << RBI::Comment.new("Please instead update this file by running `#{command}`.")
      # Prevent the header from being attached to the top-level node when generating YARD docs
      file.comments << RBI::BlankLine.new
    end

    #: (RBI::File file) -> void
    def write_empty_body_comment!(file)
      file.comments << RBI::BlankLine.new unless file.comments.empty?
      file.comments << RBI::Comment.new("THIS IS AN EMPTY RBI FILE.")
      file.comments << RBI::Comment.new("see https://github.com/Shopify/tapioca#manually-requiring-parts-of-a-gem")
    end
  end

  DEFAULT_RBI_FORMATTER = RBIFormatter.new(
    add_sig_templates: false,
    group_nodes: true,
    max_line_length: nil,
    nest_singleton_methods: true,
    nest_non_public_members: true,
    sort_nodes: true,
  ) #: RBIFormatter
end
