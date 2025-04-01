class AddEmbeddingToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :embedding, :vector, limit: 1536
  end
end
