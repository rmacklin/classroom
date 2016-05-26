class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :body
      t.integer :position, null: false
      t.references :assignment, polymorphic: true, index: true, null: false

      t.timestamps null: false
    end
  end
end
