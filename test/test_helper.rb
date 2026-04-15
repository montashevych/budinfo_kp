ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

# Stale rows in `sessions` (e.g. after DB env switches) break Rails’ post-fixture FK check
# even when no `sessions.yml` fixture exists.
module ClearStaleSessionsBeforeFixtures
  def before_setup
    if defined?(Session) && Session.connection.data_source_exists?("sessions")
      Session.delete_all
    end
    super
  end
end
ActiveSupport::TestCase.prepend(ClearStaleSessionsBeforeFixtures)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
