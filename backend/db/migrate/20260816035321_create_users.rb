class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.timestamps
      t.integer :commuter_type, default: 0
      t.string :name
    end
  end
end
