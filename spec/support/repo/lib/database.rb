# typed: true
# frozen_string_literal: true

T.bind(self, Rake::DSL)

namespace :db do
  task :abort_if_pending_migrations do
    pending_migrations = Dir["#{Kernel.__dir__}/../db/migrate/*.rb"]

    if pending_migrations.any?
      Kernel.puts "You have #{pending_migrations.size} pending migration:"

      pending_migrations.each do |pending_migration|
        name = pending_migration.split("/").last
        Kernel.puts name
      end

      Kernel.abort(%{Run `bin/rails db:migrate` to update your database then try again.})
    end
  end
end
