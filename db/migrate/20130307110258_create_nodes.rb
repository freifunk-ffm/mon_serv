class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.string :ip_address
      t.text :alert_addresses

      t.timestamps
    end
  end
  
  
end
