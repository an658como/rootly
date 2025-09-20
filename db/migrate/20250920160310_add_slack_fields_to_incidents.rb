class AddSlackFieldsToIncidents < ActiveRecord::Migration[8.0]
  def change
    # slack_channel_id already exists, so skip it
    add_column :incidents, :slack_channel_name, :string
    add_column :incidents, :declared_by, :string
    # Use slack_message_ts for thread tracking (already exists as slack_message_ts)
    # add_column :incidents, :slack_thread_ts, :string - not needed, using slack_message_ts
  end
end
