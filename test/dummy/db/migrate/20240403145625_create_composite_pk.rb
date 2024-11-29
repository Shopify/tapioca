class CreateCompositePk < ActiveRecord::Migration[7.1]
  def change
    create_table :composite_primary_keys, primary_key: [:order_id, :product_id] do |t|
      t.integer :order_id
      t.integer :product_id
      t.text :note

      t.timestamps
    end
  end
end
