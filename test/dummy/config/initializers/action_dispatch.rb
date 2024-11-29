# typed: true
# frozen_string_literal: true

# Route source locations are normally only available in development, so we need to enable this in test mode.
ActionDispatch::Routing::Mapper.route_source_locations = true
