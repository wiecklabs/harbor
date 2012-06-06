Sequel.migration do
  up do
    create_table :users do
      String :email, primary_key: true
      String :first_name, null: false
      String :last_name, null: false
      String :password_hash, null: true
    end
  end
  
  down do
    drop_table :users
  end
end