ActiveRecord::Schema[7.1].define(version: 2024_10_25_225348) do
  create_table "users", force: :cascade do |t|
    t.string "first_name", default: ""
    t.string "last_name"
  end
end
