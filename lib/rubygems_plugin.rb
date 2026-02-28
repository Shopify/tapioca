# typed: true
# frozen_string_literal: true

# If we're not running a bundler command, skip registering the plugin
return unless $PROGRAM_NAME.end_with?("bundle", "bundler")

# If the command is not update or lock, skip registering the plugin
return unless ["update", "lock"].include?(ARGV.first)

# Use a RubyGems plugin to run gem RBI synchronization when gems are updated
# This file gets required before actually installing gems, which gives us a chance to compare the lockfile and know
# if gems have actually changed

# We use this global variable to ensure that the plugin is only registered once since RubyGems / Bundler will actually
# load this multiple times
# rubocop:disable Style/GlobalVars
return if $registered_tapioca_rubygems_plugin

$registered_tapioca_rubygems_plugin = true
# rubocop:enable Style/GlobalVars

lockfile = begin
  Bundler.default_lockfile
rescue Bundler::GemfileNotFound
  nil
end
return unless lockfile

# Get the state of the lockfile before any changes are committed
current_lockfile = File.read(lockfile)

# This is a RubyGems and not a Bundler plugin, so it would get invoked multiple times during a bundle update. We workaround
# that by registering an at_exit hook to generate the RBIs once Bundler is fully done
at_exit do
  new_lockfile = File.read(lockfile)

  if current_lockfile != new_lockfile
    puts "Detected gem updates, regenerating gem RBIs"
    system("bundle exec tapioca gem")
  end
end
