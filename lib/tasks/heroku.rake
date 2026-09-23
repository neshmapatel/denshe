# Rails 8 keeps Solid Cache/Queue/Cable schemas in separate dump files.
# On Heroku those connections share DATABASE_URL, so `db:prepare` sees an
# existing primary database and never loads the Solid tables. Load them
# only when the sentinel table is missing.
namespace :db do
  desc "Load Solid Cache/Queue/Cable schemas if their tables are missing"
  task prepare_solid: :environment do
    {
      "cache" => [ "db/cache_schema.rb", "solid_cache_entries" ],
      "queue" => [ "db/queue_schema.rb", "solid_queue_jobs" ],
      "cable" => [ "db/cable_schema.rb", "solid_cable_messages" ]
    }.each do |name, (schema_file, table)|
      config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: name)
      next unless config

      ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection(config) do |conn|
        if conn.data_source_exists?(table)
          puts "db:prepare_solid #{name}: #{table} already present"
          next
        end

        load Rails.root.join(schema_file)
        puts "db:prepare_solid #{name}: loaded #{schema_file}"
      end
    end
  end
end
