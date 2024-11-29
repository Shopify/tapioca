class AddDefaultsToUser < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :age, from: nil, to: 0
    add_column :users, :active, :boolean, default: true, null: false
    change_column_default :users, :first_name, from: nil, to: ""
  end
end
