class CreateForlicationJobs < ActiveRecord::Migration
  def self.up
    create_table :forlication_jobs, :force => true do |t|
      t.string   :scope, :limit => 255             # The scope of the token (from the route)
      t.string   :token, :limit => 255             # The unique token for looking up this entry.
      t.integer  :action_limit, :default => 2000   # The number of times the action will be executed when url visited.
      t.integer  :action_count, :default => 0      # The number of times the action has been executed when url visited.
      t.text     :handler                          # YAML-encoded string of the object that will do work
      t.string   :last_error                       # reason for last failure (See Note below)
      t.datetime :failed_at                        # Set when all retries have failed (actually, by default, the record is deleted instead)

      t.timestamps
    end

    add_index :forlication_jobs, :token
  end

  def self.down
    drop_table :forlication_jobs
  end
end
