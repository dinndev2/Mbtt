class CreateHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :histories do |t|
      t.timestamps
      t.references :user
      t.references :vihicle
    end
  end
end
