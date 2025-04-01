class AddIndexesToProducts < ActiveRecord::Migration[7.0]
  def change
    add_index :products, :name
    add_index :products, :description, length: 255
  end
end
