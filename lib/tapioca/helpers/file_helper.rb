# typed: strict
# frozen_string_literal: true

require "open3"

module Tapioca
  module FileHelper
    #: (Pathname filename, Pathname | String old_path, Pathname | String new_path) -> String?
    def file_diff(filename, old_path, new_path)
      filename = filename.to_s
      stdout, stderr, status = Open3.capture3(
        "diff",
        "-u",
        "--label=Current #{filename}",
        old_path.to_s,
        "--label=Expected #{filename} (After running `bin/tapioca dsl`)",
        new_path.to_s,
      )

      unless [0, 1].include?(status.exitstatus)
        error_msg("Failed to create #{filename} diff. #{stderr.chomp}")
        return
      end

      stdout
    rescue SystemCallError => e
      error_msg("Failed to create #{filename} diff. #{e.message}")
      nil
    end

    private

    RED = "\e[31m" #: String
    CLEAR = "\e[0m" #: String

    #: (String message) -> void
    def error_msg(message)
      message = "#{RED}#{message}#{CLEAR}"
      Kernel.warn(message)
    end
  end
end
