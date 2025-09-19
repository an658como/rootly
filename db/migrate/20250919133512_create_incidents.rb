class CreateIncidents < ActiveRecord::Migration[8.0]
  def change
    create_table :incidents do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.integer :severity
      t.string :created_by
      t.string :assigned_to
      t.datetime :resolved_at
      t.datetime :acknowledged_at
      t.string :slack_channel_id
      t.string :slack_message_ts
      t.string :incident_number

      t.timestamps
    end
  end
end
